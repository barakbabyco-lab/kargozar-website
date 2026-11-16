<?php

namespace App\Console\Commands;

use App\Models\StaffUser;
use Illuminate\Console\Command;

class CreateStaffUser extends Command
{
    protected $signature = 'kargozar:staff-create
        {--name= : Staff member full name}
        {--email= : Staff member email address}
        {--mobile= : Optional Iranian mobile number}
        {--role=admin : One of admin, supervisor, expert, finance, support}';

    protected $description = 'Create a staff account without exposing its password in source control.';

    public function handle(): int
    {
        $name = trim((string) ($this->option('name') ?: $this->ask('Staff name')));
        $email = strtolower(trim((string) ($this->option('email') ?: $this->ask('Staff email'))));
        $mobile = trim((string) ($this->option('mobile') ?: $this->ask('Mobile (optional)', '')));
        $role = (string) $this->option('role');
        $roles = ['admin', 'supervisor', 'expert', 'finance', 'support'];

        if ($name === '' || ! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->error('A name and valid email address are required.');

            return self::FAILURE;
        }

        if (! in_array($role, $roles, true)) {
            $this->error('Invalid role. Allowed roles: '.implode(', ', $roles));

            return self::FAILURE;
        }

        if ($mobile !== '' && ! preg_match('/^09[0-9]{9}$/', $mobile)) {
            $this->error('Mobile must use the Iranian 09xxxxxxxxx format.');

            return self::FAILURE;
        }

        if (StaffUser::where('email', $email)->exists()) {
            $this->error('A staff account with this email already exists.');

            return self::FAILURE;
        }

        $password = $this->secret('Password');
        $confirmation = $this->secret('Confirm password');

        if ($password === '' || ! hash_equals($password, (string) $confirmation)) {
            $this->error('Password is empty or the confirmation does not match.');

            return self::FAILURE;
        }

        StaffUser::create([
            'name' => $name,
            'email' => $email,
            'mobile' => $mobile !== '' ? $mobile : null,
            'password' => $password,
            'role' => $role,
            'is_active' => true,
        ]);

        $this->info('Staff account created successfully.');

        return self::SUCCESS;
    }
}
