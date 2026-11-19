<?php

namespace Tests\Feature;

use App\Models\StaffUser;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class StaffPortalTest extends TestCase
{
    use RefreshDatabase;

    public function test_support_staff_can_sign_in_to_the_web_portal(): void
    {
        StaffUser::create([
            'name' => 'Support Agent',
            'email' => 'support@example.test',
            'password' => 'test-password',
            'role' => 'support',
            'is_active' => true,
        ]);

        $this->get('/staff/portal')->assertRedirect('/staff/portal/login');

        $this->post('/staff/portal/login', [
            'email' => 'support@example.test',
            'password' => 'test-password',
        ])->assertRedirect('/staff/portal');

        $this->get('/staff/portal')
            ->assertOk()
            ->assertSee('پنل پشتیبانی کارگزار')
            ->assertSee('گفت‌وگوها');
    }

    public function test_inactive_staff_cannot_sign_in_to_the_web_portal(): void
    {
        StaffUser::create([
            'name' => 'Inactive Agent',
            'email' => 'inactive@example.test',
            'password' => 'test-password',
            'role' => 'support',
            'is_active' => false,
        ]);

        $this->from('/staff/portal/login')
            ->post('/staff/portal/login', [
                'email' => 'inactive@example.test',
                'password' => 'test-password',
            ])
            ->assertRedirect('/staff/portal/login')
            ->assertSessionHasErrors('email');
    }
}
