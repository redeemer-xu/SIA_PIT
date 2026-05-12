<?php

namespace App\Http\Controllers\Api;

use Illuminate\Support\Facades\DB;
use App\Http\Controllers\Controller;
use App\Models\Bill;
use App\Models\Payment;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AdminController extends Controller
{
    /**
     * GET /api/admin/dashboard
     */
    public function dashboard()
    {
        try {
            $totalUsers   = DB::table('user')->where('is_archived', 0)->count();
            $totalBills   = DB::table('bill')->count();
            $totalPaid    = DB::table('bill')->where('status', 'paid')->count();
            $totalUnpaid  = DB::table('bill')->where('status', 'unpaid')->count();
            $totalRevenue = DB::table('payment')->sum('amount_paid');
            $rate         = DB::table('settings')
                                ->where('setting_key', 'rate_per_kwh')
                                ->value('setting_value');

            return response()->json([
                'success'       => true,
                'total_users'   => (int) $totalUsers,
                'total_bills'   => (int) $totalBills,
                'total_paid'    => (int) $totalPaid,
                'total_unpaid'  => (int) $totalUnpaid,
                'total_revenue' => (float) $totalRevenue,
                'rate'          => (float) $rate,
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/admin/bills
     */
    public function bills()
    {
        $bills = Bill::with('user')
            ->orderBy('dateCreated', 'desc')
            ->get()
            ->map(fn($b) => [
                'id'           => $b->id,
                'uuid'         => $b->uuid,
                'user_id'      => $b->user_id,
                'full_name'    => optional($b->user)->firstName . ' ' . optional($b->user)->lastname,
                'meter_number' => optional($b->user)->meter_number,
                'billing_date' => $b->billing_date,
                'due_date'     => $b->due_date,
                'kwh_consumed' => $b->kwh_consumed,
                'amount_due'   => $b->amount_due,
                'status'       => $b->status,
                'dateCreated'  => $b->dateCreated,
            ]);

        return response()->json(['success' => true, 'bills' => $bills]);
    }

    /**
     * POST /api/admin/bills
     * Add a new bill for a user.
     */
    public function storeBill(Request $request)
    {
        $request->validate([
            'user_id'      => 'required|exists:user,id',
            'kwh_consumed' => 'required|numeric|min:0',
            'billing_date' => 'required|date',
        ]);

        $rate    = (float) (Setting::where('setting_key', 'rate_per_kwh')->value('setting_value') ?? 11);
        $dueDays = (int)   (Setting::where('setting_key', 'due_days')->value('setting_value') ?? 30);

        // Check for duplicate bill
        $exists = Bill::where('user_id', $request->user_id)
            ->where('billing_date', $request->billing_date)
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'error'   => 'This user already has a bill for that date.',
            ], 422);
        }

        $amountDue = round($request->kwh_consumed * $rate, 2);
        $dueDate   = date('Y-m-d', strtotime($request->billing_date . " +$dueDays days"));

        $bill = Bill::create([
            'uuid'         => (string) Str::uuid(),
            'user_id'      => $request->user_id,
            'kwh_consumed' => $request->kwh_consumed,
            'amount_due'   => $amountDue,
            'billing_date' => $request->billing_date,
            'due_date'     => $dueDate,
            'status'       => 'unpaid',
        ]);

        return response()->json([
            'success'    => true,
            'message'    => 'Bill added successfully.',
            'bill_id'    => $bill->id,
            'amount_due' => $amountDue,
            'rate'       => $rate,
            'due_date'   => $dueDate,
        ], 201);
    }

    /**
     * GET /api/admin/users
     */
    public function users()
    {
        $users = User::where('is_archived', 0)
            ->withCount('bills')
            ->orderBy('dateCreated', 'desc')
            ->get()
            ->map(fn($u) => [
                'id'           => $u->id,
                'uuid'         => $u->uuid,
                'meter_number' => $u->meter_number,
                'full_name'    => $u->firstName . ' ' . $u->lastname,
                'firstName'    => $u->firstName,
                'lastname'     => $u->lastname,
                'emailAddress' => $u->emailAddress,
                'contactNumber'=> $u->contactNumber,
                'status'       => $u->status,
                'bills_count'  => $u->bills_count,
                'dateCreated'  => $u->dateCreated,
            ]);

        return response()->json(['success' => true, 'users' => $users]);
    }

    /**
     * GET /api/admin/users/{id}
     */
    public function showUser($id)
    {
        $user = User::with(['bills' => fn($q) => $q->orderBy('billing_date', 'desc')])
            ->find($id);

        if (!$user) {
            return response()->json(['success' => false, 'error' => 'User not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'user'    => [
                'id'            => $user->id,
                'meter_number'  => $user->meter_number,
                'firstName'     => $user->firstName,
                'middleName'    => $user->middleName,
                'lastname'      => $user->lastname,
                'emailAddress'  => $user->emailAddress,
                'contactNumber' => $user->contactNumber,
                'dateOfBirth'   => $user->dateOfBirth,
                'street'        => $user->street,
                'barangay'      => $user->barangay,
                'city'          => $user->city,
                'status'        => $user->status,
                'bills'         => $user->bills,
            ],
        ]);
    }

        /**
     * GET /api/admin/settings
     */
    public function getSettings()
    {
        $settings = DB::table('settings')->get()->keyBy('setting_key');

        return response()->json([
            'success'     => true,
            'rate_per_kwh' => (float) ($settings['rate_per_kwh']->setting_value ?? 11),
            'due_days'     => (int)   ($settings['due_days']->setting_value ?? 30),
            'system_name'  => $settings['system_name']->setting_value ?? 'Electricity Billing System',
            'city'         => $settings['city']->setting_value ?? '',
        ]);
    }

    /**
     * PUT /api/admin/settings
     */
    public function updateSettings(Request $request)
    {
        $request->validate([
            'rate_per_kwh' => 'sometimes|numeric|min:1',
            'due_days'     => 'sometimes|integer|min:1',
            'system_name'  => 'sometimes|string',
            'city'         => 'sometimes|string',
        ]);

        foreach (['rate_per_kwh', 'due_days', 'system_name', 'city'] as $key) {
            if ($request->has($key)) {
                DB::table('settings')
                    ->where('setting_key', $key)
                    ->update(['setting_value' => $request->$key]);
            }
        }

        return response()->json(['success' => true, 'message' => 'Settings updated successfully.']);
    }
}
