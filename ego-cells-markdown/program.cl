// Is there a way to have a kernel per layer and synchronize them or something?
// I need to do some research on that.

// Although, I could use a single program and encode all the values into a single
// int value or something. 

// Or.. it could be 3D?

__kernel void L1Rules(__read_only image2d_t in_img, __write_only image2d_t out_img) {
    int2 coord = (int2) (get_global_id(0), get_global_id(1));
    // @TODO: Get neighbor values
    write_imageui(out_img, coord, 6);
}