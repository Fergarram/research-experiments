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

// @TODO: Write to the other layers, and remember this will be done in passes.
//
//        In reality, all the trouble I went through was more about learning
//        about parallel computing. In any case I'll do it in passes which
//        actually kinda works because I'll be able to see the history.

__kernel void markdown(__read_only image3d_t in_img, __write_only image3d_t out_img) {
    int2 coord  = (int2) (get_global_id(0), get_global_id(1));
    int2 left   = (int2) (coord.x-1, coord.y);
    int2 right  = (int2) (coord.x+1, coord.y);
    int2 top    = (int2) (coord.x, coord.y-1);
    int2 bottom = (int2) (coord.x, coord.y+1);
    
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
    // if (
    //     selfL1.x != CH_SPACE
    // ) {
    //     set_layer_value(out_img, coord, 2, TK_CONTENT);
    // }

    // HEAD_SINGLE
    if (
        selfL1.x == CH_HASH &&
        left_null(coord) &&
        rightL1.x == CH_SPACE
    ) {
        set_layer_value(out_img, coord, 2, TK_HEAD_SINGLE);
    }

    // HEAD_FIRST
    if (
        selfL1.x == CH_HASH &&
        left_null(coord) &&
        rightL1.x == CH_HASH
    ) {
        set_layer_value(out_img, coord, 2, TK_HEAD_FIRST);
    }

    // HEAD_MIDDLE
    if (
        selfL1.x == CH_HASH &&
        leftL1.x == CH_HASH &&
        rightL1.x == CH_HASH &&
        (leftL2.x == TK_HEAD_FIRST || leftL2.x == TK_HEAD_MIDDLE)
    ) {
        set_layer_value(out_img, coord, 2, TK_HEAD_MIDDLE);
    }

    // HEAD_LAST
    if (
        selfL1.x == CH_HASH &&
        leftL1.x == CH_HASH &&
        rightL1.x == CH_SPACE &&
        (leftL2.x == TK_HEAD_FIRST || leftL2.x == TK_HEAD_MIDDLE)
    ) {
        set_layer_value(out_img, coord, 2, TK_HEAD_LAST);
    }

    // SNIP_FIRST
    if (
        selfL1.x == CH_TICK &&
        left_null(coord) &&
        rightL1.x == CH_TICK
    ) {
        set_layer_value(out_img, coord, 2, TK_SNIP_FIRST);
    }

    // SNIP_MIDDLE
    if (
        selfL1.x == CH_TICK &&
        leftL1.x == CH_TICK &&
        rightL1.x == CH_TICK &&
        (leftL2.x == TK_SNIP_FIRST || rightL2.x == TK_SNIP_LAST)
    ) {
        set_layer_value(out_img, coord, 2, TK_SNIP_MIDDLE);
    }

    // SNIP_LAST
    if (
        selfL1.x == CH_TICK &&
        leftL1.x == CH_TICK &&
        (rightL1.x == CH_SPACE || rightL1.x == CH_ABC) &&
        leftL2.x == TK_SNIP_MIDDLE
    ) {
        set_layer_value(out_img, coord, 2, TK_SNIP_LAST);
    }

    // SNIP_LANG
    if (
        selfL1.x == CH_ABC &&
        (rightL1.x == CH_SPACE || rightL1.x == CH_ABC) &&
        (
            (leftL1.x == CH_TICK && leftL2.x == TK_SNIP_LAST) ||
            (leftL2.x == TK_SNIP_LANG)
        )
    ) {
        set_layer_value(out_img, coord, 2, TK_SNIP_LANG);
        set_layer_value(out_img, coord, 3, LN_SNIP_BEGIN);
    }

    // LN_SNIP_BEGIN
    if (
        (
            selfL1.x == CH_SPACE ||
            selfL1.x == CH_TICK ||
            selfL2.x == TK_SNIP_LANG
        ) &&
        (
            leftL3.x == LN_SNIP_BEGIN ||
            rightL3.x == LN_SNIP_BEGIN
        )
    ) {
        set_layer_value(out_img, coord, 3, LN_SNIP_BEGIN);
    }

    // Passing the first layer from in_img to out_img
    if (get_global_id(2) == 0) set_layer_value(out_img, coord, 1, selfL1);
}
