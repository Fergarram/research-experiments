const print = @import("std").debug.print;

pub const c = @cImport({
    @cDefine("CL_TARGET_OPENCL_VERSION", "300");
    @cInclude("CL/cl.h");
});

pub const CLError = error{
    GetPlatformsFailed,
    GetPlatformInfoFailed,
    NoPlatformsFound,
    GetDevicesFailed,
    GetDeviceInfoFailed,
    NoDevicesFound,
    CreateContextFailed,
    CreateCommandQueueFailed,
    CreateProgramFailed,
    BuildProgramFailed,
    CreateKernelFailed,
    SetKernelArgFailed,
    EnqueueNDRangeKernelFailed,
    CreateBufferFailed,
    EnqueueWriteBufferFailed,
    EnqueueReadBufferFailed,
    CreateImageFailed,
    EnqueueWriteImageFailed,
    EnqueueReadImageFailed
};

pub const CLDeviceType = enum(u32) {
    CPU = c.CL_DEVICE_TYPE_CPU,
    GPU = c.CL_DEVICE_TYPE_GPU,
    ACCELERATOR = c.CL_DEVICE_TYPE_ACCELERATOR,
    DEFAULT = c.CL_DEVICE_TYPE_DEFAULT,
};

pub const CLMemFlag = enum(u64) {
    READ_WRITE = c.CL_MEM_READ_WRITE,
    WRITE_ONLY = c.CL_MEM_WRITE_ONLY,
    READ_ONLY = c.CL_MEM_READ_ONLY,
    USE_HOST_PTR = c.CL_MEM_USE_HOST_PTR,
    ALLOC_HOST_PTR = c.CL_MEM_ALLOC_HOST_PTR,
    COPY_HOST_PTR = c.CL_MEM_COPY_HOST_PTR,
    HOST_WRITE_ONLY = c.CL_MEM_HOST_WRITE_ONLY,
    HOST_READ_ONLY = c.CL_MEM_HOST_READ_ONLY,
    HOST_NO_ACCESS = c.CL_MEM_HOST_NO_ACCESS,
    SVM_FINE_GRAIN_BUFFER = c.CL_MEM_SVM_FINE_GRAIN_BUFFER,
    SVM_ATOMICS = c.CL_MEM_SVM_ATOMICS,
    KERNEL_READ_AND_WRITE = c.CL_MEM_KERNEL_READ_AND_WRITE,
};

pub const CLChannelOrder = enum(u64) {
    R = c.CL_R,
    A = c.CL_A,
    RG = c.CL_RG,
    RA = c.CL_RA,
    RGB = c.CL_RGB,
    RGBA = c.CL_RGBA,
    BGRA = c.CL_BGRA,
    ARGB = c.CL_ARGB,
    INTENSITY = c.CL_INTENSITY,
    LUMINANCE = c.CL_LUMINANCE,
    Rx = c.CL_Rx,
    RGx = c.CL_RGx,
    RGBx = c.CL_RGBx,
    DEPTH = c.CL_DEPTH,
    DEPTH_STENCIL = c.CL_DEPTH_STENCIL,
    sRGB = c.CL_sRGB,
    sRGBx = c.CL_sRGBx,
    sRGBA = c.CL_sRGBA,
    sBGRA = c.CL_sBGRA,
    ABGR = c.CL_ABGR,
};

pub const CLChannelType = enum(u64) {
    SNORM_INT8 = c.CL_SNORM_INT8,
    SNORM_INT16 = c.CL_SNORM_INT16,
    UNORM_INT8 = c.CL_UNORM_INT8,
    UNORM_INT16 = c.CL_UNORM_INT16,
    UNORM_SHORT_565 = c.CL_UNORM_SHORT_565,
    UNORM_SHORT_555 = c.CL_UNORM_SHORT_555,
    UNORM_INT_101010 = c.CL_UNORM_INT_101010,
    SIGNED_INT8 = c.CL_SIGNED_INT8,
    SIGNED_INT16 = c.CL_SIGNED_INT16,
    SIGNED_INT32 = c.CL_SIGNED_INT32,
    UNSIGNED_INT8 = c.CL_UNSIGNED_INT8,
    UNSIGNED_INT16 = c.CL_UNSIGNED_INT16,
    UNSIGNED_INT32 = c.CL_UNSIGNED_INT32,
    HALF_FLOAT = c.CL_HALF_FLOAT,
    FLOAT = c.CL_FLOAT,
    UNORM_INT24 = c.CL_UNORM_INT24,
    UNORM_INT_101010_2 = c.CL_UNORM_INT_101010_2,
};

pub const CLImageFormat = packed struct {
    order: c.cl_channel_order,
    type: c.cl_channel_type,
};

pub const CLImageDesc = packed struct {
    type: u64, // could be u64 or else
    width: usize,
    height: usize,
    depth: usize,
    arraySize: usize,
    rowPitch: usize,
    slicePitch: usize,
    numMipLevels: c.cl_uint,
    numSamples: c.cl_uint,
    memObj: c.cl_mem
};

pub fn listHardware() !void {
    var platform_ids: [16]c.cl_platform_id = undefined;
    var platform_count: c.cl_uint = undefined;

    if (c.clGetPlatformIDs(platform_ids.len, &platform_ids, &platform_count) != c.CL_SUCCESS) {
        return CLError.GetPlatformsFailed;
    }

    if (platform_count == 0) {
        print("No platforms were found.\n", .{});
        return;
    }

    print("CL Platforms:\n", .{});

    for (platform_ids[0..platform_count]) |pid, pi| {
        var pname: [1024]u8 = undefined;
        var pname_len: usize = undefined;

        if (
            c.clGetPlatformInfo(
                pid,
                c.CL_PLATFORM_NAME,
                pname.len,
                &pname,
                &pname_len
            ) != c.CL_SUCCESS
        ) {
            return CLError.GetPlatformInfoFailed;
        }

        print("  platform {d}: {s}\n", .{pi, pname[0..pname_len]});

        var device_ids: [16]c.cl_device_id = undefined;
        var device_count: c.cl_uint = undefined;

        if (
            c.clGetDeviceIDs(
                pid,
                c.CL_DEVICE_TYPE_ALL,
                device_ids.len,
                &device_ids,
                &device_count
            ) != c.CL_SUCCESS
        ) {
            return CLError.GetDevicesFailed;
        }

        if (device_count == 0) {
            print("    No devices were found.\n", .{});
            return;
        }

        for (device_ids[0..device_count]) |did, di| {
            var dname: [1024]u8 = undefined;
            var dname_len: usize = undefined;
            var dtype: c.cl_device_type = undefined;
            var dtype_len: usize = undefined;

            if (
                c.clGetDeviceInfo(
                    did,
                    c.CL_DEVICE_NAME,
                    dname.len,
                    &dname,
                    &dname_len
                ) != c.CL_SUCCESS
            ) {
                return CLError.GetDeviceInfoFailed;
            }

            if (
                c.clGetDeviceInfo(
                    did,
                    c.CL_DEVICE_TYPE,
                    @sizeOf(c.cl_device_type),
                    &dtype,
                    &dtype_len
                ) != c.CL_SUCCESS
            ) {
                return CLError.GetDeviceInfoFailed;
            }

            print("    device {d}: {s} ({s})\n", .{
                di, dname[0..dname_len], @tagName(@intToEnum(CLDeviceType, dtype))
            });
        }
    }
}

pub fn getDeviceId(platformNo: usize, deviceNo: usize) CLError!c.cl_device_id {
    var platform_ids: [16]c.cl_platform_id = undefined;
    var platform_count: c.cl_uint = undefined;

    if (c.clGetPlatformIDs(platform_ids.len, &platform_ids, &platform_count) != c.CL_SUCCESS) {
        return CLError.GetPlatformsFailed;
    }

    if (platform_count == 0) {
        return CLError.NoPlatformsFound;
    }

    var device_ids: [16]c.cl_device_id = undefined;
    var device_count: c.cl_uint = undefined;

    if (
        c.clGetDeviceIDs(
            platform_ids[platformNo],
            c.CL_DEVICE_TYPE_ALL,
            device_ids.len,
            &device_ids,
            &device_count
        ) != c.CL_SUCCESS
    ) {
        return CLError.GetDevicesFailed;
    }

    if (device_count == 0) {
        return CLError.NoDevicesFound;
    }

    return device_ids[deviceNo];
}

pub fn createContext(deviceList: *c.cl_device_id) CLError!c.cl_context {
    var ctx = c.clCreateContext(null, 1, deviceList, null, null, null);
    if (ctx == null) return CLError.CreateContextFailed;
    return ctx;
}

pub fn releaseContext(ctx: c.cl_context) void {
    print("Releasing context\n", .{});
    _ = c.clReleaseContext(ctx);
}

pub fn createCommandQueue(
    ctx: c.cl_context,
    device: c.cl_device_id
) CLError!c.cl_command_queue {
    var queue = c.clCreateCommandQueue(ctx, device, 0, null);
    if (queue == null) return CLError.CreateCommandQueueFailed;
    return queue;
}

pub fn releaseCommandQueue(queue: c.cl_command_queue) void {
    print("Releasing command queue\n", .{});
    _ = c.clFlush(queue);
    _ = c.clFinish(queue);
    _ = c.clReleaseCommandQueue(queue);
}

pub fn createProgramWithSource(
    ctx: c.cl_context,
    source: [*:0]const u8
) CLError!c.cl_program {
    var c_string: [*c]const u8 = source;
    var program = c.clCreateProgramWithSource(ctx, 1, &c_string, null, null);
    if (program == null) return CLError.CreateProgramFailed;
    return program;
}

pub fn releaseProgram(program: c.cl_program) void {
    print("Releasing program\n", .{});
    _ = c.clReleaseProgram(program);
}

pub fn buildProgramForDevice(program: c.cl_program, devicePtr: *c.cl_device_id) CLError!void {
    var errno = c.clBuildProgram(program, 1, devicePtr, null, null, null);
    if (errno != c.CL_SUCCESS) {
        print("errno: {}\n", .{errno});
        var logBuffer = [_]u8{' '} ** 10000;
        var bufferSize: usize = 1;
        _ = c.clGetProgramBuildInfo(
            program,
            devicePtr.*,
            c.CL_PROGRAM_BUILD_LOG,
            10000 * @sizeOf(u8),
            @ptrCast(*anyopaque, &logBuffer),
            &bufferSize
        );

        print("{s}\n", .{logBuffer[0..bufferSize]});

        return CLError.BuildProgramFailed;
    }
}

pub fn createKernel(
    program: c.cl_program,
    name: [*:0]const u8
) CLError!c.cl_kernel {
    var kernel = c.clCreateKernel(program, name, null);
    if (kernel == null) return CLError.CreateKernelFailed;
    return kernel;
}

pub fn releaseKernel(kernel: c.cl_kernel) void {
    print("Releasing kernel\n", .{});
    _ = c.clReleaseKernel(kernel);
}

pub fn createBuffer(
    ctx: c.cl_context,
    memFlag: CLMemFlag,
    bufferSize: usize
) CLError!c.cl_mem {
    var buffer = c.clCreateBuffer(ctx, @enumToInt(memFlag), bufferSize, null, null);
    if (buffer == null) return CLError.CreateBufferFailed;
    return buffer;
}

pub fn releaseMemObj(memObj: c.cl_mem) void {
    print("Releasing memObj\n", .{});
    _ = c.clReleaseMemObject(memObj);
}

pub fn enqueueWriteBufferWithData(
    queue: c.cl_command_queue,
    buffer: c.cl_mem,
    blocking: bool,
    offset: usize,
    comptime T: type,
    data: [*]T,
    size: usize
) CLError!void {
    if (
        c.clEnqueueWriteBuffer(
            queue,
            buffer,
            if (blocking) c.CL_TRUE else c.CL_FALSE,
            offset,
            size * @sizeOf(T),
            data,
            0,
            null,
            null) != c.CL_SUCCESS
    ) {
        return CLError.EnqueueWriteBufferFailed;
    }
}

pub fn enqueueReadBufferToDataPtr(
    queue: c.cl_command_queue,
    buffer: c.cl_mem,
    blocking: bool,
    offset: usize,
    comptime T: type,
    dataPtr: [*]T,
    size: usize
) CLError!void {
    if (
        c.clEnqueueReadBuffer(
            queue,
            buffer,
            if (blocking) c.CL_TRUE else c.CL_FALSE,
            offset,
            size * @sizeOf(T),
            dataPtr,
            0,
            null,
            null) != c.CL_SUCCESS
    ) {
        return CLError.EnqueueReadBufferFailed;
    }
}

pub fn createImage(
    ctx: c.cl_context,
    memFlag: CLMemFlag,
    format: CLImageFormat,
    width: usize,
    height: usize,
    depth: usize,
) CLError!c.cl_mem {
    var imageDesc = CLImageDesc{
        .type = if (depth > 0) c.CL_MEM_OBJECT_IMAGE3D else c.CL_MEM_OBJECT_IMAGE2D,
        .width = width,
        .height = height,
        .depth = depth,
        .arraySize = 0,
        .rowPitch = 0,
        .slicePitch = 0,
        .numMipLevels = 0,
        .numSamples = 0,
        .memObj = null
    };
    var cImageDesc = @bitCast(c.cl_image_desc, imageDesc);
    var cImageFormat = @bitCast(c.cl_image_format, format);
    var image = c.clCreateImage(
        ctx,
        @enumToInt(memFlag),
        &cImageFormat,
        &cImageDesc,
        null,
        null
    );
    if (image == null) return CLError.CreateImageFailed;
    return image;
}

pub fn enqueueWriteImageWithData(
    queue: c.cl_command_queue,
    image: c.cl_mem,
    blocking: bool,
    origin: [3]usize,
    region: [3]usize,
    rowPitch: usize,
    slicePitch: usize,
    comptime T: type,
    data: [*]T
) CLError!void {
    var errno = c.clEnqueueWriteImage(
        queue,
        image,
        if (blocking) c.CL_TRUE else c.CL_FALSE,
        @ptrCast([*c]const usize, &origin),
        @ptrCast([*c]const usize, &region),
        rowPitch,
        slicePitch,
        data,
        0,
        null,
        null
    );
    if (errno != c.CL_SUCCESS) {
        print("errno: {}\n", .{errno});
        return CLError.EnqueueWriteImageFailed;
    }
}

pub fn enqueueReadImageWithData(
    queue: c.cl_command_queue,
    image: c.cl_mem,
    blocking: bool,
    origin: [3]usize,
    region: [3]usize,
    rowPitch: usize,
    slicePitch: usize,
    comptime T: type,
    data: [*]T
) CLError!void {
    var errno = c.clEnqueueReadImage(
        queue,
        image,
        if (blocking) c.CL_TRUE else c.CL_FALSE,
        @ptrCast([*c]const usize, &origin),
        @ptrCast([*c]const usize, &region),
        rowPitch,
        slicePitch,
        data,
        0,
        null,
        null
    );
    if (errno != c.CL_SUCCESS) {
        print("errno: {}\n", .{errno});
        return CLError.EnqueueReadImageFailed;
    }
}

pub fn setKernelArg(
    kernel: c.cl_kernel,
    index: u32,
    memPtr: *c.cl_mem
) CLError!void {
    var errno = c.clSetKernelArg(kernel, index, @sizeOf(c.cl_mem), memPtr);
    if (errno != c.CL_SUCCESS) {
        print("errno: {}\n", .{errno});
        return CLError.SetKernelArgFailed;
    }
}

pub fn enqueueNDRangeKernelWithoutEvents(
    queue: c.cl_command_queue,
    kernel: c.cl_kernel,
    dimensions: u32,
    globalSize: [3]usize,
    localSize: ?[3]usize
) CLError!void {
    // @NOTE: Careful with how much shit we send to the kernels...
    if (
        c.clEnqueueNDRangeKernel(
            queue,
            kernel,
            dimensions,
            null, // Always null until new version...
            @ptrCast([*c]const usize, &globalSize),
            if (localSize == null) null else @ptrCast([*c]const usize, &localSize),
            0,
            null,
            null) != c.CL_SUCCESS
    ) {
        return CLError.EnqueueNDRangeKernelFailed;
    }
}