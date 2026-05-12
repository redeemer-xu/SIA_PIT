<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Bill extends Model
{
    protected $table = 'bill';

    public $timestamps = false;

    protected $fillable = [
        'uuid',
        'user_id',
        'kwh_consumed',
        'amount_due',
        'billing_date',
        'period_month',
        'period_year',
        'due_date',
        'status',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function payment()
    {
        return $this->hasOne(Payment::class, 'bill_id');
    }
}
