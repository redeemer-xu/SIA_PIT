<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $table = 'payment';

    public $timestamps = false;

    protected $fillable = [
        'uuid',
        'bill_id',
        'user_id',
        'amount_paid',
        'payment_date',
        'payment_method',
        'reference_number',
    ];

    public function bill()
    {
        return $this->belongsTo(Bill::class, 'bill_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
