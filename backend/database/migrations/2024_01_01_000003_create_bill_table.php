<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bill', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->unsignedBigInteger('user_id');
            $table->decimal('kwh_consumed', 10, 2)->default(0);
            $table->decimal('amount_due', 10, 2)->default(0);
            $table->date('billing_date');
            $table->tinyInteger('period_month')->nullable();
            $table->year('period_year')->nullable();
            $table->date('due_date');
            $table->enum('status', ['unpaid', 'paid', 'overdue'])->default('unpaid');
            $table->timestamp('dateCreated')->useCurrent();

            $table->foreign('user_id')
                  ->references('id')->on('user')
                  ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bill');
    }
};
