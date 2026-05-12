<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class AdminMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        // The token name for admins is 'admin-token'
        if (!$user || !$user->currentAccessToken() || 
            !str_contains($user->currentAccessToken()->name, 'admin')) {
            return response()->json([
                'success' => false,
                'error'   => 'Unauthorized. Admin access required.',
            ], 403);
        }

        return $next($request);
    }
}
