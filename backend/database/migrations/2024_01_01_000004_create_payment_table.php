<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('bill_id');
            $table->unsignedBigInteger('user_id');
            $table->decimal('amount_paid', 10, 2)->default(0);
            $table->timestamp('payment_date')->useCurrent();
            $table->enum('payment_method', ['cash', 'gcash', 'maya', 'bank'])->default('cash');
            $table->string('reference_number', 50)->nullable();

            $table->foreign('bill_id')
                  ->references('id')->on('bill')
                  ->onDelete('cascade');

            $table->foreign('user_id')
                  ->references('id')->on('user')
                  ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment');
    }
};
