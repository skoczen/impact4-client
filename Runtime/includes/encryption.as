/* Encryption -- This file support random number generation and encryption (RC4 and DH)
 * Copyright 2002-2003 UC Regents & Veterans Medical Research Foundation
 *
 * Random Number Generator by John Walker <http://www.fourmilab.ch/>
 * Base64 Encoder by Masanao Izumo <mo@goice.co.jp>
 *
 * $Id: encryption.as,v 1.7 2004/01/25 03:19:02 abansod Exp $
 */


// The dhPrime is poorly choosen. We don't have a lot of bits to work with
// thus, we must choose something like this. If we had 768 or 1024 bits
// to use, look at RFC2539 for some Well Known p & g values

// a good prime might be
// var dhPrime = 6468175387379; // p
// The maximum Flash's "number" datatype can hold is a double precision
// IEE-754, e.g. 1.79E+308
_global.dhPrime = 17; // p
_global.dhBase = 2; // g
_global.dhPublicKey = 0;
_global.encryptionKey = "sample";

/*

    L'Ecuyer's two-sequence generator with a Bays-Durham shuffle
    on the back-end.  Schrage's algorithm is used to perform
    64-bit modular arithmetic within the 32-bit constraints of
    JavaScript.

    Bays, C. and S. D. Durham.  ACM Trans. Math. Software: 2 (1976)
        59-64.

    L'Ecuyer, P.  Communications of the ACM: 31 (1968) 742-774.

    Schrage, L.  ACM Trans. Math. Software: 5 (1979) 132-138.

*/

// Schrage's modular multiplication algorithm
function uGen(old, a, q, r, m)
{
	var t;

	t = Math.floor(old / q);
	t = a * (old - (t * q)) - (t * r);
	return Math.round((t < 0) ? (t + m) : t);
}

// Return next raw value
function LEnext()
{
	var i;

	this.gen1 = uGen(this.gen1, 40014, 53668, 12211, 2147483563);
	this.gen2 = uGen(this.gen2, 40692, 52774, 3791, 2147483399);

	/* Extract shuffle table index from most significant part
	   of the previous result. */

	i = Math.floor(this.state / 67108862);

	// New state is sum of generators modulo one of their moduli

	this.state = Math.round((this.shuffle[i] + this.gen2) % 2147483563);

	// Replace value in shuffle table with generator 1 result

	this.shuffle[i] = this.gen1;

	return this.state;
}

//  Return next random integer between 0 and n inclusive
function LEnint(n)
{
	return Math.floor(this.next() / (1 + 2147483562 / (n + 1)));
}

//  Constructor.  Called with seed value
function LEcuyer(s)
{
	var i;
	
	this.shuffle = new Array(32);	
	this.gen1 = this.gen2 = (s & 0x7FFFFFFF);
	for (i = 0; i < 19; i++)
	{
		this.gen1 = uGen(this.gen1, 40014, 53668, 12211, 2147483563);	
	}

	// Fill the shuffle table with values
	for (i = 0; i < 32; i++)
	{
		this.gen1 = uGen(this.gen1, 40014, 53668, 12211, 2147483563);
		this.shuffle[31 - i] = this.gen1;	
	}
	
	this.state = this.shuffle[0];
	this.next = LEnext;
	this.nextInt = LEnint;
}

function SeedRandomization()
{
	var n;
	var seed = Math.round((new Date()).getTime() % Math.pow(2, 31));
	var ran0 = new LEcuyer((seed ^ Math.round(getTimer() % Math.pow(2, 31))) & 0x7FFFFFFF);
	for (var j = 0; j < (5 + ((seed >> 3) & 0xF)); j++)
	{
		n = ran0.nextInt(31);
	}
	while (n-- >= 0)
	{
		seed = ((seed << 11) | (seed >>> (32 - 11))) ^ ran0.next();
	}
	seed &= 0x7FFFFFFF;

	_global.LERandom = new LEcuyer(seed);
	st("encryption: L'Ecuyer randomizer seeded with " + seed + ", test value " + LERandom.nextInt(100));
}




/* Copyright (C) 1999 Masanao Izumo <mo@goice.co.jp>
 * Version: 1.0
 * LastModified: Dec 25 1999
 * This library is free.  You can redistribute it and/or modify it.
 */

/*
 * Interfaces:
 * b64 = base64encode(data);
 * data = base64decode(b64);
 */


var base64EncodeChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
var base64DecodeChars = new Array(
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
    -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
    -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1);

function base64Encode(str)
{
    var out, i, len;
    var c1, c2, c3;

    len = str.length;
    i = 0;
    out = "";
    while(i < len)
    {
	c1 = str.charCodeAt(i++) & 0xff;
	if(i == len)
	{
	    out += base64EncodeChars.charAt(c1 >> 2);
	    out += base64EncodeChars.charAt((c1 & 0x3) << 4);
	    out += "==";
	    break;
	}
	c2 = str.charCodeAt(i++);
	if(i == len)
	{
	    out += base64EncodeChars.charAt(c1 >> 2);
	    out += base64EncodeChars.charAt(((c1 & 0x3)<< 4) | ((c2 & 0xF0) >> 4));
	    out += base64EncodeChars.charAt((c2 & 0xF) << 2);
	    out += "=";
	    break;
	}
	c3 = str.charCodeAt(i++);
	out += base64EncodeChars.charAt(c1 >> 2);
	out += base64EncodeChars.charAt(((c1 & 0x3)<< 4) | ((c2 & 0xF0) >> 4));
	out += base64EncodeChars.charAt(((c2 & 0xF) << 2) | ((c3 & 0xC0) >>6));
	out += base64EncodeChars.charAt(c3 & 0x3F);
    }
    return out;
}

function base64Decode(str)
{
    var c1, c2, c3, c4;
    var i, len, out;

    len = str.length;
    i = 0;
    out = "";
    while(i < len)
    {
	/* c1 */
	do
        {
	    c1 = base64DecodeChars[str.charCodeAt(i++) & 0xff];
	}
        while(i < len && c1 == -1);
	if(c1 == -1)
	    break;

	/* c2 */
	do
        {
	    c2 = base64DecodeChars[str.charCodeAt(i++) & 0xff];
	}
        while(i < len && c2 == -1);
	if(c2 == -1)
	    break;

	out += String.fromCharCode((c1 << 2) | ((c2 & 0x30) >> 4));

	/* c3 */
	do
        {
	    c3 = str.charCodeAt(i++) & 0xff;
	    if(c3 == 61)
		return out;
	    c3 = base64DecodeChars[c3];
	}
        while(i < len && c3 == -1);
	if(c3 == -1)
	    break;

	out += String.fromCharCode( ((c2 & 0xF) << 4)| ((c3 & 0x3C) >> 2) );

	/* c4 */
	do
        {
	    c4 = str.charCodeAt(i++) & 0xff;
	    if(c4 == 61)
		return out;
	    c4 = base64DecodeChars[c4];
	}
        while(i < len && c4 == -1);
	if(c4 == -1)
	    break;
	out += String.fromCharCode(((c3 & 0x03) << 6) | c4);
    }
    return out;
}

// convert a string to array of chars
function stringToArray(s)
{
	var retVal = new Array();
	for(var i = 0; i < s.length; i++)
		retVal[i] = s.charAt(i);
}

// convert an array of chars to a string
function arrayToString(a)
{
	var retVal = "";
	for(var i = 0; i < a.length; i++)
		retVal += a[i];
}

// generate a random private key
function generatePrivateKey()
{
	var theRandom = LERandom.nextInt(dhPrime-2);
	// st("genprikey: lh random is " + theRandom);
	_global.dhPrivateKey = theRandom;
}

// generate a public key
function generatePublicKey()
{
	// seed the randomizer if it hasn't been already
	if(typeof(_global.LERandom) == "undefined")
		SeedRandomization();

	// Generate the private key, x
	generatePrivateKey();
	// st("fo: " + dhBase + "^" + dhPrivateKey + "%" + dhPrime + " = " + (Math.pow(dhBase,dhPrivateKey) % dhPrime));
	// st("base to prikey " + Math.pow(dhBase,dhPrivateKey));
	// Calculate y
	dhPublicKey = Math.pow(dhBase,dhPrivateKey) % dhPrime;
	return dhPublicKey;
}

// create the encryption key based on teh remote public key
function createEncryptionKey(remotePublicKey)
{
	// st("remote pk " + remotePublicKey);
	// st("dh privkey " + dhPrivateKey);
	// st("dh prime " + dhPrime);

	_global.encryptionKey = Math.pow(remotePublicKey,dhPrivateKey) % dhPrime;
	st("encryption: encryptionkey is " + encryptionKey);

	// get rid of the private key for paranoia's sake
	delete dhPrivateKey;

	return true;
}

// return the public key
function getPublicKey()
{
	if(dhPublicKey == null)
		generatePublicKey();

	return dhPublicKey;
}

// encrypt then b64 encode
function base64RC4Encrypt(s)
{
	// st(now() + " " + s);
	var temp = RC4Encrypt(s, RC4Init(_global.encryptionKey));
	// st("encrypting " + s + " as " + temp);
	return base64Encode(temp);
	//return base64Encode(s);
}

// b64 decode and decrypt
function base64RC4Decrypt(s)
{
	return RC4Decrypt(base64Decode(s), RC4Init(_global.encryptionKey));
	//return base64Decode(s);
}

// Perform key setup, and return the sbox
function RC4Init(theKey)
{
	var randomiser = 0;
	var temp = 0;
	var i = 0;
	var j = 0;
	var counter = 0;
	var sbox = new Array (256);
	var keyBox;

	theKey = new String(theKey);

	// clean up the sbox
	for(i=0;i < sbox.length;i++)
	{
		sbox[i] = i;
	}



	if (theKey.length > 0)
	{
		keyBox = new Array(256);

		for(counter=0; counter < 256; counter++)
		{
			keyBox[counter] = theKey.charCodeAt((counter % theKey.length));
		}
		for (counter = 0;counter < 256;counter++)
		{

			randomiser = (randomiser + (sbox[counter] + keyBox[counter])) % 256;
			
			temp = sbox[counter];
			sbox[counter] = sbox[randomiser];
			sbox[randomiser] = temp;
		}
	}
	return sbox;
}

// rc4 encrypt text with sbox
function RC4Encrypt(text, sbox)
{
	return text;
	if(text.length > 0)
	{
		//generate a keystream of the desired length
		var cyphertext = "";
		var i = 0;
		var j = 0;

		for(var counter = 0; counter < text.length; counter++)
		{
			i = (i + 1)%256;
			j = (j + sbox[i])%256;
			
			var temp = sbox[i];
			sbox[i] = sbox[j];
			sbox[j] = temp;
			
			var t = (sbox[i] + sbox[j])%256;
			
			var tempString = String.fromCharCode( sbox[t]^text.charCodeAt(counter) );

			cyphertext += tempString;
		}
		
		return cyphertext;
	}
}

// rc4 decyrpt with sbox
function RC4Decrypt(text, sbox)
{
	return text;
	if(text.length > 0)
	{
		//generate a keystream of the desired length
		var cyphertext = new String("");
		var i = 0;
		var j = 0;

		for(var counter = 0; counter < text.length; counter++)
		{
			i = (i + 1)%256;
			j = (j + sbox[i])%256;
			
			var temp = sbox[i];
			sbox[i] = sbox[j];
			sbox[j] = temp;
			
			var t = (sbox[i] + sbox[j])%256;
			
			var tempString = String.fromCharCode( sbox[t]^ text.charCodeAt(counter) );

			cyphertext += tempString;
		}
	
		return cyphertext;
	}
}

