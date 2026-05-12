<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    // The existing DB table is called 'user' (not 'users')
    protected $table = 'user';

    public $timestamps = false; // table uses dateCreated, not created_at/updated_at

    protected $fillable = [
        'uuid',
        'meter_number',
        'profile_picture',
        'firstName',
        'middleName',
        'lastname',
        'emailAddress',
        'contactNumber',
        'dateOfBirth',
        'username',
        'password',
        'street',
        'barangay',
        'city',
        'status',
        'is_archived',
        'archived_at',
    ];

    protected $hidden = ['password'];

    // Relationships
    public function bills()
    {
        return $this->hasMany(Bill::class, 'user_id');
    }

    public function payments()
    {
        return $this->hasMany(Payment::class, 'user_id');
    }
}
