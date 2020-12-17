#!/usr/bin/octave -q
close all
clear
clc

printf('Load the configuration\n');
configuration

printf('Set the configuration\n');
set_configuration

printf('Write the configuration to file\n');
write_configuration

printf('done\n');


