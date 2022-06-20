#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable

#define CH_SPACE         0
#define CH_ABC           1
#define CH_123           2
#define CH_SYM           3
#define CH_DOT           4
#define CH_HASH          5
#define CH_CURLY_DASH    6
#define CH_DASH          7
#define CH_OPEN_PAR      8
#define CH_CLOSED_PAR    9
#define CH_OPEN_SQR      10
#define CH_CLOSED_SQR    11
#define CH_TICK          12
#define CH_STAR          13
#define CH_ESCAPE        14
#define CH_BIGGER_THAN   15

#define TK_EMPTY         0
#define TK_CONTENT       1
#define TK_HEAD_SINGLE   2
#define TK_HEAD_FIRST    3
#define TK_HEAD_MIDDLE   4
#define TK_HEAD_LAST     5
#define TK_SNIP_FIRST    6
#define TK_SNIP_MIDDLE   7
#define TK_SNIP_LAST     8
#define TK_SNIP_LANG     9
#define TK_SNIP_CONTENT  10

#define LN_EMPTY_LINE    0
#define LN_HEADING       1
#define LN_SNIP_BEGIN    2
#define LN_SNIP_END      3
#define LN_SNIP_TEXT     4
#define LN_TEXT          5

#define DSAMP (CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST)

#define left_null(cell)   (cell.x-1 < 0)
#define right_null(cell)  (cell.x+1 > 127)
#define top_null(cell)    (cell.y-1 < 0)
#define bottom_null(cell) (cell.y+1 > 127)

#define get_layer_value(img, pos, z)    (read_imageui(img, (int4)(pos.x, pos.y, z-1, 0)))
#define set_layer_value(img, pos, z, v) (write_imageui(img, (int4)(pos.x, pos.y, z-1, 0), v))


//
// Execution
//

__kernel void markdown(__read_only image3d_t in_img, __write_only image3d_t out_img) {
    int4 imgDim = get_image_dim(in_img);
    int2 coord  = (int2) (get_global_id(0), get_global_id(1));
    int2 left   = (int2) (coord.x-1, coord.y);
    int2 right  = (int2) (coord.x+1, coord.y);
    int2 top    = (int2) (coord.x, coord.y-1);
    int2 bottom = (int2) (coord.x, coord.y+1);
    int2 prev = (int2) (-1, -1); // Represents null
    int2 next = (int2) (-1, -1); // Represents null
    bool topWall = coord.y-1 == -1;
    bool leftWall = coord.x-1 == -1;
    bool bottomWall = coord.y+1 == imgDim.x; // Using X here assumes size is always square
    bool rightWall = coord.x+1 == imgDim.x;

    // If first in row but not the first row in buffer jump to the last col in previous row.
    if (coord.x == 0 && coord.y != 0) {
        prev = (int2) (imgDim.x-1, coord.y-1);

    // Otherwise just use the left neighbor
    } else if (coord.x > 0) {
        prev = left;
    }

    // If last in row but not last row in buffer jump to the first col in the next row.
    if (coord.x == imgDim.x-1 && coord.y != imgDim.y-1) {
        next = (int2) (0, coord.y+1);
    
    // Otherwise just use the right neighbor
    } else if (coord.x < imgDim.x-1) {
        next = right;
    }

    uint4 firstInRowL3 = get_layer_value(in_img, (int2) (0, coord.y), 3);

    uint4 selfL1 = get_layer_value(in_img, coord, 1);
    uint4 selfL2 = get_layer_value(in_img, coord, 2);
    uint4 selfL3 = get_layer_value(in_img, coord, 3);
    // uint4 selfL4 = get_layer_value(in_img, coord, 4);
    // uint4 selfL5 = get_layer_value(in_img, coord, 5);

    uint4 leftL1 = get_layer_value(in_img, left, 1);
    uint4 leftL2 = get_layer_value(in_img, left, 2);
    uint4 leftL3 = get_layer_value(in_img, left, 3);
    // uint4 leftL4 = get_layer_value(in_img, left, 4);
    // uint4 leftL5 = get_layer_value(in_img, left, 5);

    uint4 rightL1 = get_layer_value(in_img, right, 1);
    uint4 rightL2 = get_layer_value(in_img, right, 2);
    uint4 rightL3 = get_layer_value(in_img, right, 3);
    // uint4 rightL4 = get_layer_value(in_img, right, 4);
    // uint4 rightL5 = get_layer_value(in_img, right, 5);

    uint4 topL1 = get_layer_value(in_img, top, 1);
    uint4 topL2 = get_layer_value(in_img, top, 2);
    uint4 topL3 = get_layer_value(in_img, top, 3);
    // uint4 topL4 = get_layer_value(in_img, top, 4);
    // uint4 topL5 = get_layer_value(in_img, top, 5);

    uint4 bottomL1 = get_layer_value(in_img, bottom, 1);
    uint4 bottomL2 = get_layer_value(in_img, bottom, 2);
    uint4 bottomL3 = get_layer_value(in_img, bottom, 3);
    // uint4 bottomL4 = get_layer_value(in_img, bottom, 4);
    // uint4 bottomL5 = get_layer_value(in_img, bottom, 5);

    // CONTENT
    if (
        selfL1.x == CH_ABC ||
        selfL1.x == CH_123 ||
        selfL1.x == CH_SYM ||
        selfL1.x == CH_DOT
    ) {
        set_layer_value(out_img, coord, 2, TK_CONTENT);
    }

    // HEAD_SINGLE
    else if (
        selfL1.x == CH_HASH &&
        left_null(coord) &&
        rightL1.x == CH_SPACE &&
        selfL3.x != LN_SNIP_TEXT
    ) {
        set_layer_value(out_img, coord, 2, TK_HEAD_SINGLE);
    }

    // HEAD_FIRST
    else if (
        selfL1.x == CH_HASH &&
        left_null(coord) &&
        rightL1.x == CH_HASH
    ) {
        set_layer_value(out_img, coord, 2, TK_HEAD_FIRST);
    }

    // HEAD_MIDDLE
    else if (
        selfL1.x == CH_HASH &&
        leftL1.x == CH_HASH &&
        rightL1.x == CH_HASH &&
        (leftL2.x == TK_HEAD_FIRST || leftL2.x == TK_HEAD_MIDDLE)
    ) {
        set_layer_value(out_img, coord, 2, TK_HEAD_MIDDLE);
    }

    // HEAD_LAST
    else if (
        selfL1.x == CH_HASH &&
        leftL1.x == CH_HASH &&
        rightL1.x == CH_SPACE &&
        (leftL2.x == TK_HEAD_FIRST || leftL2.x == TK_HEAD_MIDDLE)
    ) {
        set_layer_value(out_img, coord, 2, TK_HEAD_LAST);
    }

    // SNIP_FIRST
    else if (
        selfL1.x == CH_TICK &&
        left_null(coord) &&
        rightL1.x == CH_TICK
    ) {
        set_layer_value(out_img, coord, 2, TK_SNIP_FIRST);
    }

    // SNIP_MIDDLE
    else if (
        selfL1.x == CH_TICK &&
        leftL1.x == CH_TICK &&
        rightL1.x == CH_TICK &&
        (leftL2.x == TK_SNIP_FIRST || rightL2.x == TK_SNIP_LAST)
    ) {
        set_layer_value(out_img, coord, 2, TK_SNIP_MIDDLE);
    }

    // SNIP_LAST
    else if (
        selfL1.x == CH_TICK &&
        leftL1.x == CH_TICK &&
        (rightL1.x == CH_SPACE || rightL1.x == CH_ABC) &&
        leftL2.x == TK_SNIP_MIDDLE
    ) {
        set_layer_value(out_img, coord, 2, TK_SNIP_LAST);
    }

    // SNIP_LANG
    else if (
        selfL1.x == CH_ABC &&
        (rightL1.x == CH_SPACE || rightL1.x == CH_ABC) &&
        (
            (leftL1.x == CH_TICK && leftL2.x == TK_SNIP_LAST) ||
            (leftL2.x == TK_SNIP_LANG)
        )
    ) {
        set_layer_value(out_img, coord, 2, TK_SNIP_LANG);
    }

    // SNIP_CONTENT
    else if (selfL3.x == LN_SNIP_TEXT) {
        set_layer_value(out_img, coord, 2, TK_SNIP_CONTENT);
    }

    // L2 ELSE
    else {
        set_layer_value(out_img, coord, 2, TK_EMPTY);
    }

    // LN_TEXT
    if (
        (
            selfL2.x != TK_SNIP_FIRST &&
            selfL2.x != TK_SNIP_MIDDLE && 
            selfL2.x != TK_SNIP_LAST &&
            selfL2.x != TK_SNIP_LANG &&
            selfL3.x != LN_HEADING &&
            topL3.x != LN_SNIP_BEGIN &&
            leftL3.x != LN_SNIP_TEXT &&
            (
                topL3.x == LN_TEXT ||
                bottomL3.x == LN_TEXT ||
                leftL3.x == LN_TEXT ||
                rightL3.x == LN_TEXT ||
                firstInRowL3.x == LN_TEXT
            )
        ) ||
        (
            (
                selfL2.x != TK_HEAD_SINGLE && 
                selfL2.x != TK_HEAD_FIRST && 
                selfL2.x != TK_HEAD_MIDDLE && 
                selfL2.x != TK_HEAD_LAST
            ) &&
            (
                top_null(coord) ||
                bottom_null(coord) ||
                topL3.x == LN_SNIP_END
            )
        )
    ) {
        set_layer_value(out_img, coord, 3, LN_TEXT);
    }
    
    // LN_HEADING
    else if (
        leftL3.x == LN_HEADING ||
        rightL3.x == LN_HEADING ||
        firstInRowL3.x == LN_HEADING ||
        (
            (
                selfL2.x != TK_SNIP_FIRST &&
                selfL2.x != TK_SNIP_MIDDLE && 
                selfL2.x != TK_SNIP_LAST &&
                selfL2.x != TK_SNIP_LANG 
            ) &&
            (
                selfL2.x == TK_HEAD_SINGLE || 
                selfL2.x == TK_HEAD_FIRST || 
                selfL2.x == TK_HEAD_MIDDLE || 
                selfL2.x == TK_HEAD_LAST
            ) &&
            (
                top_null(coord) ||
                selfL3.x == LN_TEXT
            )
        )
    ) {
        set_layer_value(out_img, coord, 3, LN_HEADING);
    }

    // LN_SNIP_BEGIN
    else if (
        firstInRowL3.x == LN_SNIP_BEGIN ||
        leftL3.x == LN_SNIP_BEGIN ||
        rightL3.x == LN_SNIP_BEGIN ||
        (
            (
                selfL2.x == TK_SNIP_FIRST ||
                selfL2.x == TK_SNIP_MIDDLE ||
                selfL2.x == TK_SNIP_LAST ||
                selfL2.x == TK_SNIP_LANG
            ) &&
            (
                top_null(coord) ||
                topL3.x == LN_HEADING ||
                topL3.x == LN_TEXT
            )
        )
    ) {
        // printf("Here\n");
        set_layer_value(out_img, coord, 3, LN_SNIP_BEGIN);
    }
    
    // LN_SNIP_TEXT
    else if (
        firstInRowL3.x == LN_SNIP_TEXT ||
        (
            selfL3.x != LN_SNIP_BEGIN &&
            selfL3.x != LN_SNIP_END &&
            selfL2.x != TK_SNIP_FIRST &&
            selfL2.x != TK_SNIP_MIDDLE &&
            selfL2.x != TK_SNIP_LAST &&
            topL3.x != LN_SNIP_END &&
            topL3.x != LN_TEXT &&
            leftL3.x != LN_TEXT &&
            leftL3.x != LN_HEADING &&
            (
                topL3.x == LN_SNIP_BEGIN ||
                bottomL3.x == LN_SNIP_END ||
                leftL3.x == LN_SNIP_TEXT ||
                rightL3.x == LN_SNIP_TEXT ||
                topL3.x == LN_SNIP_TEXT ||
                bottomL3.x == LN_SNIP_TEXT
            )
        )
    ) {
        set_layer_value(out_img, coord, 3, LN_SNIP_TEXT);
    }
    
    // LN_SNIP_END
    else if (
        leftL3.x == LN_SNIP_END ||
        rightL3.x == LN_SNIP_END ||
        firstInRowL3.x == LN_SNIP_END ||
        (
            topL3.x == LN_SNIP_TEXT &&
            (
                selfL2.x == TK_SNIP_FIRST ||
                selfL2.x == TK_SNIP_MIDDLE ||
                selfL2.x == TK_SNIP_LAST
            )
        )
    ) {
        set_layer_value(out_img, coord, 3, LN_SNIP_END);
    }

    // L3 ELSE
    else {
        set_layer_value(out_img, coord, 3, LN_EMPTY_LINE);
    }

    // Passing the first layer from in_img to out_img
    if (get_global_id(2) == 0) set_layer_value(out_img, coord, 1, selfL1);
}
