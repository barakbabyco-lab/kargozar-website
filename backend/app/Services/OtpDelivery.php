<?php

namespace App\Services;

interface OtpDelivery
{
    public function send(string $mobile, string $code): void;
}
