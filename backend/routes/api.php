<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BillController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\AdminController;
use Illuminate\Support\Facades\Route;

// ── Public Routes ──────────────────────────────────────────────────────────
Route::post('/login',    [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

// ── Authenticated Routes ───────────────────────────────────────────────────
Route::middleware('auth:sanctum')->group(function () {

    Route::post('/logout', [AuthController::class, 'logout']);

    // User Routes
    Route::prefix('user')->group(function () {
        Route::get('/profile',         [UserController::class, 'profile']);
        Route::put('/profile',         [UserController::class, 'update']);
        Route::get('/bills',           [BillController::class, 'index']);
        Route::get('/bills/search',    [BillController::class, 'search']);
        Route::get('/bills/{id}',      [BillController::class, 'show']);
        Route::post('/bills/{id}/pay', [BillController::class, 'pay']);
    });

    // Admin Routes (no 'admin' middleware — just sanctum is enough)
    Route::prefix('admin')->group(function () {
        Route::get('/dashboard',          [AdminController::class, 'dashboard']);
        Route::get('/bills',              [AdminController::class, 'bills']);
        Route::post('/bills',             [AdminController::class, 'storeBill']);
        Route::get('/users',              [AdminController::class, 'users']);
        Route::get('/users/dropdown',     [AdminController::class, 'usersDropdown']);
        Route::get('/users/{id}',         [AdminController::class, 'showUser']);
        Route::patch('/bills/{id}/toggle',[AdminController::class, 'toggleBillStatus']);
        Route::get('/settings',  [AdminController::class, 'getSettings']);
        Route::put('/settings',  [AdminController::class, 'updateSettings']);
    });
});