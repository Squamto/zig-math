const Self = @This();
const std = @import("std");

const Vec3 = @import("vector.zig").Vec3;
const Vec4 = @import("vector.zig").Vec4;

pub const Quat4 = struct {
    data: @Vector(4, f32) = @splat(0),

    pub fn conjugate(self: Quat4) Quat4 {
        return .{ .data = Vec4.init(.{ -self.data[0], -self.data[1], -self.data[2], self.data[3] }).data };
    }

    pub fn norm(self: Quat4) f32 {
        return @reduce(.Add, self.data * self.data);
    }

    pub fn invert(self: Quat4) Quat4 {
        return .{ .data = self.conjugate().data / @as(@TypeOf(self.data), @splat(self.norm())) };
    }

    pub fn normalize(self: Quat4) Quat4 {
        return .{ .data = self.data / @as(@TypeOf(self.data), @splat(std.math.sqrt(self.norm()))) };
    }

    pub fn mul(lhs: Quat4, rhs: Quat4) Quat4 {
        //QuatMul(QUAT *q1, QUAT *q2, QUAT *res){
        //float A, B, C, D, E, F, G, H;
        //A = (q1->w + q1->x)*(q2->w + q2->x);
        //B = (q1->z - q1->y)*(q2->y - q2->z);
        //C = (q1->w - q1->x)*(q2->y + q2->z);
        //D = (q1->y + q1->z)*(q2->w - q2->x);
        //E = (q1->x + q1->z)*(q2->x + q2->y);
        //F = (q1->x - q1->z)*(q2->x - q2->y);
        //G = (q1->w + q1->y)*(q2->w - q2->z);
        //H = (q1->w - q1->y)*(q2->w + q2->z);
        //res->w = B + (-E - F + G + H) /2;
        //res->x = A - (E + F + G + H)/2;
        //res->y = C + (E - F + G - H)/2;
        //res->z = D + (E - F - G + H)/2;

        const A = (lhs.data[3] + lhs.data[0]) * (rhs.data[3] + rhs.data[0]);
        const B = (lhs.data[2] - lhs.data[1]) * (rhs.data[1] - rhs.data[2]);
        const C = (lhs.data[3] - lhs.data[0]) * (rhs.data[1] + rhs.data[2]);
        const D = (lhs.data[1] + lhs.data[2]) * (rhs.data[3] - rhs.data[0]);
        const E = (lhs.data[0] + lhs.data[2]) * (rhs.data[0] + rhs.data[1]);
        const F = (lhs.data[0] - lhs.data[2]) * (rhs.data[0] - rhs.data[1]);
        const G = (lhs.data[3] + lhs.data[1]) * (rhs.data[3] - rhs.data[2]);
        const H = (lhs.data[3] - lhs.data[1]) * (rhs.data[3] + rhs.data[2]);

        return .{ .data = .{
            A - (E + F + G + H) / 2.0,
            C + (E - F + G - H) / 2.0,
            D + (E - F - G + H) / 2.0,
            B + (-E - F + G + H) / 2.0,
        } };
    }

    pub fn from_vec(vec: Vec3) Quat4 {
        return .{ .data = .{ vec.data[0], vec.data[1], vec.data[2], 0.0 } };
    }

    pub fn from_axis_angle(axis: Vec3, angle: f32) Quat4 {
        const half_angle = angle / 2.0;
        const sin_half_angle = std.math.sin(half_angle);
        const cos_half_angle = std.math.cos(half_angle);
        const new_axis = axis.normalize().scale(sin_half_angle);
        const result = Quat4{ .data = Vec4.compose(new_axis, cos_half_angle).data };
        return result.normalize();
    }

    pub fn form_euler(angles: Vec3) Quat4 {
        const half_x = angles.x() / 2.0;
        const half_y = angles.y() / 2.0;
        const half_z = angles.z() / 2.0;
        const sin_half_x = std.math.sin(half_x);
        const cos_half_x = std.math.cos(half_x);
        const sin_half_y = std.math.sin(half_y);
        const cos_half_y = std.math.cos(half_y);
        const sin_half_z = std.math.sin(half_z);
        const cos_half_z = std.math.cos(half_z);

        const result = Quat4{ .data = .{
            sin_half_x * cos_half_y * cos_half_z - cos_half_x * sin_half_y * sin_half_z,
            cos_half_x * sin_half_y * cos_half_z + sin_half_x * cos_half_y * sin_half_z,
            cos_half_x * cos_half_y * sin_half_z - sin_half_x * sin_half_y * cos_half_z,
            cos_half_x * cos_half_y * cos_half_z + sin_half_x * sin_half_y * sin_half_z,
        } };
        return result.normalize();
    }

    pub fn rotate_vector(self: Quat4, vec: Vec3) Vec3 {
        const qvec = Quat4.from_vec(vec);
        const result = self.mul(qvec).mul(self.conjugate());
        return Vec3.init(.{ result.data[0], result.data[1], result.data[2] });
    }

    test norm {
        const epsilon = std.math.floatEps(f32);
        const quat = Quat4{ .data = Vec4.init(.{ 1.0, 2.0, 3.0, 4.0 }).data };
        const expected = 30.0;

        try std.testing.expectApproxEqRel(quat.norm(), expected, epsilon);
    }

    test conjugate {
        const epsilon = std.math.floatEps(f32);
        const quat = Quat4{ .data = Vec4.init(.{ 1.0, 2.0, 3.0, 4.0 }).data };
        const expected = Vec4.init(.{ -1.0, -2.0, -3.0, 4.0 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.conjugate().data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.conjugate().data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.conjugate().data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.conjugate().data[3], epsilon);
    }

    test invert {
        const epsilon = std.math.floatEps(f32);
        const quat = Quat4{ .data = Vec4.init(.{ 1.0, 2.0, 3.0, 4.0 }).data };
        const expected = Vec4.init(.{ -0.03333333, -0.06666667, -0.1, 0.13333333 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.invert().data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.invert().data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.invert().data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.invert().data[3], epsilon);
    }

    test normalize {
        const epsilon = std.math.floatEps(f32);
        const quat = Quat4{ .data = Vec4.init(.{ 1.0, 2.0, 3.0, 4.0 }).data };
        const expected = Vec4.init(.{ 0.18257419, 0.36514837, 0.54772256, 0.73029674 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.normalize().data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.normalize().data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.normalize().data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.normalize().data[3], epsilon);
    }

    test mul {
        const epsilon = std.math.floatEps(f32);
        const quat1 = Quat4{ .data = Vec4.init(.{ 1.0, 2.0, 3.0, 4.0 }).data };
        const quat2 = Quat4{ .data = Vec4.init(.{ 5.0, 6.0, 7.0, 8.0 }).data };
        const result = quat1.normalize().mul(quat2.normalize());
        const expected = Vec4.init(.{
            0.3321819194149599,
            0.6643638388299197,
            0.6643638388299196,
            -0.08304547985373997,
        });

        try std.testing.expectApproxEqAbs(expected.data[0], result.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], result.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], result.data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], result.data[3], epsilon);
    }

    test from_axis_angle {
        const epsilon = std.math.floatEps(f32);
        var quat = Quat4.from_axis_angle(Vec3.init(.{ 1.0, 0.0, 0.0 }), 0.0);
        var expected = Vec4.init(.{ 0.0, 0.0, 0.0, 1.0 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.data[3], epsilon);

        quat = Quat4.from_axis_angle(Vec3.init(.{ 1.0, 0.0, 0.0 }), std.math.pi);
        expected = Vec4.init(.{ 1.0, 0.0, 0.0, 0.0 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.data[3], epsilon);

        quat = Quat4.from_axis_angle(Vec3.init(.{ 1, 2, 3 }), 1.25);
        expected = Vec4.init(.{ 0.1563738, 0.3127476, 0.4691215, 0.8109631 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.data[3], epsilon);
    }

    test form_euler {
        const epsilon = std.math.floatEps(f32);
        var quat = Quat4.form_euler(Vec3.init(.{ 0.0, 0.0, 0.0 }));
        var expected = Vec4.init(.{ 0.0, 0.0, 0.0, 1.0 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.data[3], epsilon);

        quat = Quat4.form_euler(Vec3.init(.{ 0.0, 0.0, std.math.pi }));
        expected = Vec4.init(.{ 0.0, 0.0, 1.0, 0.0 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.data[3], epsilon);

        quat = Quat4.form_euler(Vec3.init(.{ 0.0, std.math.pi, 0.0 }));
        expected = Vec4.init(.{ 0.0, 1.0, 0.0, 0.0 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.data[3], epsilon);

        quat = Quat4.form_euler(Vec3.init(.{ std.math.pi, 0.0, 0.0 }));
        expected = Vec4.init(.{ 1.0, 0.0, 0.0, 0.0 });

        try std.testing.expectApproxEqAbs(expected.data[0], quat.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], quat.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], quat.data[2], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[3], quat.data[3], epsilon);
    }

    test rotate_vector {
        const epsilon = std.math.floatEps(f32);
        const quat = Quat4.form_euler(Vec3.init(.{ 0.0, 0.0, std.math.pi }));
        const vec = Vec3.init(.{ 1.0, 0.0, 0.0 });
        const expected = Vec3.init(.{ -1.0, 0.0, 0.0 });

        const result = quat.rotate_vector(vec);

        try std.testing.expectApproxEqAbs(expected.data[0], result.data[0], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[1], result.data[1], epsilon);
        try std.testing.expectApproxEqAbs(expected.data[2], result.data[2], epsilon);
    }
};