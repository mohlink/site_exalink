<?php
declare(strict_types=1);

/* Example only. Save a filled copy OUTSIDE the public web root.
   Never commit actual passwords, account addresses or SMTP credentials. */
return [
    'autoload' => '/ABSOLUTE/PRIVATE/PATH/vendor/autoload.php',
    'smtp_host' => 'smtp.example.invalid',
    'smtp_port' => 587,
    'smtp_username' => 'REPLACE_ME',
    'smtp_password' => 'REPLACE_ME',
    'smtp_encryption' => 'tls',
    'from_email' => 'REPLACE_WITH_VERIFIED_SENDER',
    'from_name' => 'EXALINK Website',
    'to_email' => 'REPLACE_WITH_CONFIRMED_RECIPIENT',
];
