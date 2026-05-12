<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('meter_number', 20)->unique();
            $table->string('profile_picture', 255)->nullable();
            $table->string('firstName', 100);
            $table->string('middleName', 100)->nullable();
            $table->string('lastname', 100);
            $table->string('emailAddress', 150)->unique();
            $table->string('contactNumber', 20)->nullable();
            $table->date('dateOfBirth')->nullable();
            $table->string('username', 100)->unique();
            $table->string('password');
            $table->string('street', 255)->nullable();
            $table->string('barangay', 100)->nullable();
            $table->string('city', 100)->nullable();
            $table->timestamp('dateCreated')->useCurrent();
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->tinyInteger('is_archived')->default(0);
            $table->timestamp('archived_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user');
    }
};
