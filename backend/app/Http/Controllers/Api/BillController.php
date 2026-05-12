<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bill;
use App\Models\Payment;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class BillController extends Controller
{
    /**
     * GET /api/user/bills
     * Returns all bills for the authenticated user.
     */
    public function index(Request $request)
    {
        $bills = Bill::where('user_id', $request->user()->id)
            ->orderBy('billing_date', 'desc')
            ->get()
            ->map(fn($b) => $this->formatBill($b));

        return response()->json([
            'success' => true,
            'bills'   => $bills,
        ]);
    }

    /**
     * GET /api/user/bills/{id}
     * Returns a single bill detail.
     */
    public function show(Request $request, $id)
    {
        $bill = Bill::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$bill) {
            return response()->json(['success' => false, 'error' => 'Bill not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'bill'    => $this->formatBill($bill),
        ]);
    }

    /**
     * POST /api/user/bills/{id}/pay
     * Pay a bill.
     */
    public function pay(Request $request, $id)
    {
        $request->validate([
            'amount'         => 'required|numeric|min:0.01',
            'payment_method' => 'required|in:cash,gcash,maya,bank',
        ]);

        $bill = Bill::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$bill) {
            return response()->json(['success' => false, 'error' => 'Bill not found.'], 404);
        }

        if ($bill->status === 'paid') {
            return response()->json(['success' => false, 'error' => 'Bill is already paid.'], 422);
        }

        // Create payment record
        $payment = Payment::create([
            'uuid'             => (string) Str::uuid(),
            'bill_id'          => $bill->id,
            'user_id'          => $request->user()->id,
            'amount_paid'      => $request->amount,
            'payment_method'   => $request->payment_method,
            'reference_number' => strtoupper(Str::random(10)),
        ]);

        // Update bill status
        $bill->update(['status' => 'paid']);

        return response()->json([
            'success'      => true,
            'payment_uuid' => $payment->uuid,
        ]);
    }

    /**
     * GET /api/user/bills/search?q=...
     * Search bills by status or date.
     */
    public function search(Request $request)
    {
        $q = $request->query('q', '');

        $bills = Bill::where('user_id', $request->user()->id)
            ->where(function ($query) use ($q) {
                $query->where('status', 'like', "%$q%")
                      ->orWhere('billing_date', 'like', "%$q%")
                      ->orWhere('amount_due', 'like', "%$q%");
            })
            ->orderBy('billing_date', 'desc')
            ->get()
            ->map(fn($b) => $this->formatBill($b));

        return response()->json([
            'success' => true,
            'bills'   => $bills,
        ]);
    }

    // ── Helper ───────────────────────────────────────────────────────────────
    private function formatBill(Bill $bill): array
    {
        return [
            'id'           => $bill->id,
            'uuid'         => $bill->uuid,
            'user_id'      => $bill->user_id,
            'billing_date' => $bill->billing_date,
            'due_date'     => $bill->due_date,
            'kwh_consumed' => $bill->kwh_consumed,
            'amount_due'   => $bill->amount_due,
            'status'       => $bill->status,
            'dateCreated'  => $bill->dateCreated,
        ];
    }
}
