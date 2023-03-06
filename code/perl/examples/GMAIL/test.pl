#!/usr/bin/perl

use strict;
use warnings;

use Email::Send::SMTP::Gmail;

my ($mail,$error)=Email::Send::SMTP::Gmail->new( -smtp=>'smtp.gmail.com',
                                                 -login=>'ASXpredictor@gmail.com',
                                                 -pass=>'Withnail&1');


print "session error: $error" unless ($mail!=-1);

$mail->send(-to=>'mrjohncorry@gmail.com', -subject=>'Hello!', -body=>'Just testing it', -attachments=>'./test.txt');

$mail->bye;
