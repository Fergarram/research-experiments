#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable

#define CH_SPACE = 0
#define CH_ABC = 1
#define CH_123 = 2
#define CH_SYM = 3
#define CH_POINT = 4
#define CH_HASH = 5
#define CH_CURLY_DASH = 5
#define CH_DASH = 6
#define CH_OPEN_PAR = 7
#define CH_CLOSED_PAR = 8
#define CH_OPEN_SQR = 9
#define CH_CLOSED_SQR = 10
#define CH_TICK = 11
#define CH_STAR = 12
#define CH_ESCAPE = 13
#define CH_BIGGER_THAN = 14

#define DSAMP = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST

#define get_layer_value(img, pos, z) (read_imageui(img, (int4)(pos.x, pos.y, z, 0)))
#define set_layer_value(img, pos, z, v) (write_imageui(img, (int4)(pos.x, pos.y, z, 0), v))


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
    
    uint4 selfL1 = get_layer_value(in_img, coord, 0);
    uint4 selfL2 = get_layer_value(in_img, coord, 1);
    uint4 selfL3 = get_layer_value(in_img, coord, 2);
    uint4 selfL4 = get_layer_value(in_img, coord, 3);
    uint4 selfL5 = get_layer_value(in_img, coord, 4);
    
    set_layer_value(out_img, coord, get_global_id(2), selfL1);
}