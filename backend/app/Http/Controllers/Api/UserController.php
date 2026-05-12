<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class UserController extends Controller
{
    /**
     * GET /api/user/profile
     */
    public function profile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'user'    => [
                'id'             => $user->id,
                'uuid'           => $user->uuid,
                'meter_number'   => $user->meter_number,
                'firstName'      => $user->firstName,
                'middleName'     => $user->middleName,
                'lastname'       => $user->lastname,
                'emailAddress'   => $user->emailAddress,
                'contactNumber'  => $user->contactNumber,
                'dateOfBirth'    => $user->dateOfBirth,
                'street'         => $user->street,
                'barangay'       => $user->barangay,
                'city'           => $user->city,
                'status'         => $user->status,
                'profile_picture'=> $user->profile_picture,
                'dateCreated'    => $user->dateCreated,
            ],
        ]);
    }

    /**
     * PUT /api/user/profile
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'firstName'     => 'sometimes|required|string|max:100',
            'lastname'      => 'sometimes|required|string|max:100',
            'email'         => 'sometimes|required|email|unique:user,emailAddress,' . $user->id,
            'contact'       => 'nullable|string|max:20',
            'dateOfBirth'   => 'nullable|date',
            'street'        => 'nullable|string',
            'barangay'      => 'nullable|string',
            'city'          => 'nullable|string',
        ]);

        $user->update(array_filter([
            'firstName'     => $request->firstName,
            'middleName'    => $request->middleName,
            'lastname'      => $request->lastname,
            'emailAddress'  => $request->email,
            'contactNumber' => $request->contact,
            'dateOfBirth'   => $request->dateOfBirth,
            'street'        => $request->street,
            'barangay'      => $request->barangay,
            'city'          => $request->city,
        ], fn($v) => $v !== null));

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully.',
            'user'    => [
                'id'            => $user->id,
                'firstName'     => $user->firstName,
                'lastname'      => $user->lastname,
                'emailAddress'  => $user->emailAddress,
                'contactNumber' => $user->contactNumber,
                'street'        => $user->street,
                'barangay'      => $user->barangay,
                'city'          => $user->city,
            ],
        ]);
    }
}
