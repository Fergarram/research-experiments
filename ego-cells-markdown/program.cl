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
#define TK_PARAGRAPH     1
#define TK_HEADING_1     2
#define TK_HEADING_2     3
#define TK_HEADING_3     4
#define TK_HEADING_4     5
#define TK_HEADING_5     6
#define TK_HEADING_6     7
#define TK_UL_ITEM       8
#define TK_OL_ITEM       9
#define TK_SNIP_BLOCK    10

#define LN_EMPTY_LINE    0
#define LN_HEADING       1
#define LN_SNIP_BORDER   2
#define LN_SNIP_TEXT     3
#define LN_TEXT          4

#define DSAMP (CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST)

#define left_null(cell)   (cell.x-1 < 0)
#define right_null(cell)  (cell.x+1 > 127)
#define top_null(cell)    (cell.y-1 < 0)
#define bottom_null(cell) (cell.y+1 > 127)

#define get_layer_value(img, pos, z)    (read_imageui(img, (int4)(pos.x, pos.y, z-1, 0)))
#define set_layer_value(img, pos, z, v) (write_imageui(img, (int4)(pos.x, pos.y, z-1, 0), v))

#define rightN(img, pos, z, n) (get_layer_value(img, (int2)(pos.x+n, pos.y), z))
#define leftN(img, pos, z, n) (get_layer_value(img, (int2)(pos.x-n, pos.y), z))
#define topN(img, pos, z, n) (get_layer_value(img, (int2)(pos.x, pos.y-n), z))
#define downN(img, pos, z, n) (get_layer_value(img, (int2)(pos.x, pos.y+n), z))


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
    int2 prev = (int2) (-1, -1);
    int2 next = (int2) (-1, -1);
    bool topWall = coord.y-1 == -1;
    bool leftWall = coord.x-1 == -1;
    bool bottomWall = coord.y+1 == imgDim.y;
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

    uint4 selfL1 = get_layer_value(in_img, coord, 1);
    uint4 selfL2 = get_layer_value(in_img, coord, 2);
    uint4 selfL3 = get_layer_value(in_img, coord, 3);

    uint4 firstInRowL1 = get_layer_value(in_img, (int2) (0, coord.y), 1);
    uint4 firstInRowL2 = get_layer_value(in_img, (int2) (0, coord.y), 2);
    uint4 firstInRowL3 = get_layer_value(in_img, (int2) (0, coord.y), 3);


    // SNIP BORDER
    if (
        leftWall &&
        selfL1.x == CH_TICK &&
        rightN(in_img, coord, 1, 1).x == CH_TICK &&
        rightN(in_img, coord, 1, 2).x == CH_TICK
    ) {
        set_layer_value(out_img, coord, 3, LN_SNIP_BORDER);
        set_layer_value(out_img, coord, 2, TK_SNIP_BLOCK);
    }

    else if (
        firstInRowL3.x == LN_SNIP_BORDER
    ) {
        set_layer_value(out_img, coord, 3, LN_SNIP_BORDER);
        set_layer_value(out_img, coord, 2, TK_SNIP_BLOCK);
    }

    // SNIP CONTENT
    else if (
        coord.y-2 == -1 && // @TODO: Should I replace this expression with something more formal?
        topN(in_img, coord, 3, 1).x == LN_SNIP_BORDER
    ) {
        set_layer_value(out_img, coord, 3, LN_SNIP_TEXT);
        set_layer_value(out_img, coord, 2, TK_SNIP_BLOCK);
    }

    else if (
        selfL3.x != LN_SNIP_BORDER &&
        topN(in_img, coord, 3, 1).x == LN_SNIP_TEXT
    ) {
        set_layer_value(out_img, coord, 3, LN_SNIP_TEXT);
        set_layer_value(out_img, coord, 2, TK_SNIP_BLOCK);
    }

    else if (
        topN(in_img, coord, 3, 1).x == LN_SNIP_BORDER &&
        topN(in_img, coord, 3, 2).x == LN_TEXT
    ) {
        set_layer_value(out_img, coord, 3, LN_SNIP_TEXT);
        set_layer_value(out_img, coord, 2, TK_SNIP_BLOCK);
    }

    // NON-SNIP CONTENT
    else if (
        selfL1.x != CH_TICK &&
        topWall &&
        leftWall
    ) {
        set_layer_value(out_img, coord, 3, LN_TEXT);
    }

    else if (
        firstInRowL3.x == LN_TEXT
    ) {
        set_layer_value(out_img, coord, 3, LN_TEXT);
    }

    else if (
        topN(in_img, coord, 3, 1).x == LN_SNIP_BORDER &&
        topN(in_img, coord, 3, 2).x == LN_SNIP_TEXT
    ) {
        set_layer_value(out_img, coord, 3, LN_TEXT);
    }

    else if (
        selfL3.x != LN_SNIP_BORDER &&
        topN(in_img, coord, 3, 1).x == LN_TEXT
    ) {
        set_layer_value(out_img, coord, 3, LN_TEXT);
    }

    // HEADING 1
    if (
        selfL3.x == LN_TEXT &&
        leftWall &&
        selfL1.x == CH_HASH &&
        rightN(in_img, coord, 1, 1).x == CH_SPACE
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_1);
    }

    else if (
        selfL3.x == LN_TEXT &&
        firstInRowL2.x == TK_HEADING_1
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_1);
    }

    // HEADING 2
    if (
        selfL3.x == LN_TEXT &&
        leftWall &&
        selfL1.x == CH_HASH &&
        rightN(in_img, coord, 1, 1).x == CH_HASH &&
        rightN(in_img, coord, 1, 2).x == CH_SPACE
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_2);
    }

    else if (
        selfL3.x == LN_TEXT &&
        firstInRowL2.x == TK_HEADING_2
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_2);
    }

    // HEADING 3
    if (
        selfL3.x == LN_TEXT &&
        leftWall &&
        selfL1.x == CH_HASH &&
        rightN(in_img, coord, 1, 1).x == CH_HASH &&
        rightN(in_img, coord, 1, 2).x == CH_HASH &&
        rightN(in_img, coord, 1, 3).x == CH_SPACE
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_3);
    }

    else if (
        selfL3.x == LN_TEXT &&
        firstInRowL2.x == TK_HEADING_3
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_3);
    }

    // HEADING 4
    if (
        selfL3.x == LN_TEXT &&
        leftWall &&
        selfL1.x == CH_HASH &&
        rightN(in_img, coord, 1, 1).x == CH_HASH &&
        rightN(in_img, coord, 1, 2).x == CH_HASH &&
        rightN(in_img, coord, 1, 3).x == CH_HASH &&
        rightN(in_img, coord, 1, 4).x == CH_SPACE
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_4);
    }

    else if (
        selfL3.x == LN_TEXT &&
        firstInRowL2.x == TK_HEADING_4
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_4);
    }

    // HEADING 5
    if (
        selfL3.x == LN_TEXT &&
        leftWall &&
        selfL1.x == CH_HASH &&
        rightN(in_img, coord, 1, 1).x == CH_HASH &&
        rightN(in_img, coord, 1, 2).x == CH_HASH &&
        rightN(in_img, coord, 1, 3).x == CH_HASH &&
        rightN(in_img, coord, 1, 4).x == CH_HASH &&
        rightN(in_img, coord, 1, 5).x == CH_SPACE
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_5);
    }

    else if (
        selfL3.x == LN_TEXT &&
        firstInRowL2.x == TK_HEADING_5
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_5);
    }

    // HEADING 6
    if (
        selfL3.x == LN_TEXT &&
        leftWall &&
        selfL1.x == CH_HASH &&
        rightN(in_img, coord, 1, 1).x == CH_HASH &&
        rightN(in_img, coord, 1, 2).x == CH_HASH &&
        rightN(in_img, coord, 1, 3).x == CH_HASH &&
        rightN(in_img, coord, 1, 4).x == CH_HASH &&
        rightN(in_img, coord, 1, 5).x == CH_HASH &&
        rightN(in_img, coord, 1, 6).x == CH_SPACE
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_6);
    }

    else if (
        selfL3.x == LN_TEXT &&
        firstInRowL2.x == TK_HEADING_6
    ) {
        set_layer_value(out_img, coord, 2, TK_HEADING_6);
    }

    // PARAGRAPH
    else if (
        selfL3.x == LN_TEXT &&
        leftWall &&
        (
            selfL1.x == CH_ABC ||
            selfL1.x == CH_SYM ||
            selfL1.x == CH_DOT ||
            selfL1.x == CH_CURLY_DASH ||
            selfL1.x == CH_OPEN_PAR ||
            selfL1.x == CH_CLOSED_PAR ||
            selfL1.x == CH_OPEN_SQR ||
            selfL1.x == CH_CLOSED_SQR ||
            selfL1.x == CH_TICK ||
            selfL1.x == CH_BIGGER_THAN ||
            (
                // Could this be improved with a GA ?
                selfL1.x == CH_SPACE &&
                rightN(in_img, coord, 1, 1).x != CH_SPACE
            ) ||
            (
                selfL1.x == CH_123 &&
                rightN(in_img, coord, 1, 1).x != CH_SPACE
            ) ||
            (
                selfL1.x == CH_HASH &&
                rightN(in_img, coord, 1, 1).x != CH_SPACE &&
                rightN(in_img, coord, 1, 1).x != CH_HASH
            ) ||
            (
                selfL1.x == CH_DASH &&
                rightN(in_img, coord, 1, 1).x != CH_SPACE
            ) ||
            (
                selfL1.x == CH_STAR &&
                rightN(in_img, coord, 1, 1).x != CH_SPACE
            )
        )
    ) {
        set_layer_value(out_img, coord, 2, TK_PARAGRAPH);
    }

    else if (
        selfL3.x == LN_TEXT &&
        firstInRowL2.x == TK_PARAGRAPH
    ) {
        set_layer_value(out_img, coord, 2, TK_PARAGRAPH);
    }

    // UNORDERED LIST
    else if (
        selfL3.x == LN_TEXT &&
        leftWall &&
        selfL1.x == CH_STAR &&
        rightN(in_img, coord, 1, 1).x == CH_SPACE
    ) {
        set_layer_value(out_img, coord, 2, TK_UL_ITEM);
    }

    else if (
        selfL3.x == LN_TEXT &&
        firstInRowL2.x == TK_UL_ITEM
    ) {
        set_layer_value(out_img, coord, 2, TK_UL_ITEM);
    }

    // Passing the first layer from in_img to out_img
    if (get_global_id(2) == 0) set_layer_value(out_img, coord, 1, selfL1);
}
