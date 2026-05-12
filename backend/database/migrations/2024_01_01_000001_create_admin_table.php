<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('admin', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('firstName', 100);
            $table->string('middleName', 100)->nullable();
            $table->string('lastname', 100);
            $table->string('username', 100)->unique();
            $table->string('password');
            $table->timestamp('dateCreated')->useCurrent();
        });

        // Seed a default admin (password: admin123)
        DB::table('admin')->insert([
            'uuid'        => \Illuminate\Support\Str::uuid(),
            'firstName'   => 'System',
            'lastname'    => 'Admin',
            'username'    => 'admin',
            'password'    => bcrypt('admin123'),
            'dateCreated' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('admin');
    }
};
