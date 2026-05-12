<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * POST /api/login
     * Checks admin table first, then user table.
     */
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        // ── Check Admin table first ──────────────────────────────────────
        $admin = Admin::where('username', $request->username)->first();

        if ($admin) {
            if (!Hash::check($request->password, $admin->password)) {
                return response()->json([
                    'success' => false,
                    'error'   => 'Incorrect password. Please try again.',
                ], 401);
            }

            $token = $admin->createToken('admin-token')->plainTextToken;

            return response()->json([
                'success'  => true,
                'role'     => 'admin',
                'token'    => $token,
                'id'       => $admin->id,
                'name'     => $admin->firstName . ' ' . $admin->lastname,
                'username' => $admin->username,
            ]);
        }

        // ── Check User table ─────────────────────────────────────────────
        $user = User::where('username', $request->username)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'error'   => 'Username not found. Please try again.',
            ], 401);
        }

        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'error'   => 'Incorrect password. Please try again.',
            ], 401);
        }

        if ($user->status === 'inactive') {
            return response()->json([
                'success' => false,
                'error'   => 'Your account is inactive. Please contact the administrator.',
            ], 403);
        }

        $token = $user->createToken('user-token')->plainTextToken;

        return response()->json([
            'success'      => true,
            'role'         => 'user',
            'token'        => $token,
            'id'           => $user->id,
            'name'         => $user->firstName . ' ' . $user->lastname,
            'username'     => $user->username,
            'meter_number' => $user->meter_number,
            'email'        => $user->emailAddress,
        ]);
    }

    /**
     * POST /api/register
     */
    public function register(Request $request)
    {
        $request->validate([
            'firstName' => 'required|string|max:100',
            'lastname'  => 'required|string|max:100',
            'email'     => 'required|email|unique:user,emailAddress',
            'username'  => 'required|string|min:4|unique:user,username',
            'password'  => 'required|string|min:8',
            'street'    => 'required|string',
            'barangay'  => 'required|string',
            'city'      => 'required|string',
        ]);

        // Auto-generate meter number (MTR-001, MTR-002, ...)
        $last = User::orderBy('id', 'desc')->value('meter_number');
        $nextNum = 1;
        if ($last && preg_match('/MTR-(\d+)/', $last, $m)) {
            $nextNum = intval($m[1]) + 1;
        }
        do {
            $meterNumber = 'MTR-' . str_pad($nextNum, 3, '0', STR_PAD_LEFT);
            $exists = User::where('meter_number', $meterNumber)->exists();
            if ($exists) $nextNum++;
        } while ($exists);

        $user = User::create([
            'uuid'          => (string) Str::uuid(),
            'meter_number'  => $meterNumber,
            'firstName'     => $request->firstName,
            'middleName'    => $request->middleName ?? null,
            'lastname'      => $request->lastname,
            'emailAddress'  => $request->email,
            'contactNumber' => $request->contact ?? null,
            'dateOfBirth'   => $request->dateOfBirth ?? null,
            'username'      => $request->username,
            'password'      => Hash::make($request->password),
            'street'        => $request->street,
            'barangay'      => $request->barangay,
            'city'          => $request->city,
            'status'        => 'active',
        ]);

        return response()->json([
            'success'      => true,
            'message'      => 'Registration successful.',
            'meter_number' => $user->meter_number,
        ], 201);
    }

    /**
     * POST /api/logout
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
        ]);
    }
}
