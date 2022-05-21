*** coding: utf-8 ***
*** Frank Fang ***
*** 2022/05/21 ***


clear all
set more off
graph drop _all
set scheme s1color 
set seed 1234


*** Note: Before running the code, please 
*** 1. Set your working directory as the father dir of the folder "Code"
*** 2. Copy "./Code/datatotex.ado" to your STATA ado folder

cd "/Users/frankfang/Desktop/Blockchain/Final/方清源Code"

do "./Code/Clean.do"
do "./Code/Regress.do"
