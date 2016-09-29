//
//  Encrypt.cpp
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/7.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#include "Crypto.h"
#include "openssl/conf.h"
#include "openssl/err.h"
#include "openssl/rand.h"
#include <vector>
#include <cassert>

static const std::string supportedCipher[kCipherTypeMaxSupported] = {
    "rc4",
    "aes-128-cfb",
    "aes-192-cfb",
    "aes-256-cfb",
    "bf-cfb",
    "camellia-128-cfb",
    "camellia-192-cfb",
    "camellia-256-cfb",
    "cast5-cfb",
    "des-cfb",
    "idea-cfb",
    "rc2-cfb",
    "seed-cfb"
};

Crypto::Crypto(CipherType cipherType, const std::string& password)
:   cipherType_(cipherType)
{
    ERR_load_crypto_strings();
    OpenSSL_add_all_algorithms();
    OPENSSL_config(NULL);
    
    const EVP_CIPHER* cipher = EVP_get_cipherbyname(supportedCipher[cipherType_].c_str());
    unsigned char key[EVP_MAX_KEY_LENGTH];
    unsigned char tmp[EVP_MAX_IV_LENGTH];
    unsigned char iv[EVP_MAX_IV_LENGTH];
    
    memset(iv, 0, EVP_MAX_IV_LENGTH);
    RAND_bytes(iv, EVP_MAX_IV_LENGTH);
    int keyLength = EVP_BytesToKey(cipher, EVP_md5(), NULL, (const unsigned char *)password.c_str(), (int)password.size(), 1, key, tmp);
    encryptCTX_ = EVP_CIPHER_CTX_new();
    EVP_CIPHER_CTX_init(encryptCTX_);
    EVP_CipherInit_ex(encryptCTX_, cipher, NULL, NULL, NULL, 1);
    EVP_CIPHER_CTX_set_key_length(encryptCTX_, keyLength);
    EVP_CIPHER_CTX_set_padding(encryptCTX_, 1);
    EVP_CipherInit_ex(encryptCTX_, NULL, NULL, key, iv, 1);
    
    decryptCTX_ = EVP_CIPHER_CTX_new();
    EVP_CIPHER_CTX_init(decryptCTX_);
    EVP_CipherInit_ex(decryptCTX_, cipher, NULL, NULL, NULL, 0);
    EVP_CIPHER_CTX_set_key_length(decryptCTX_, keyLength);
    EVP_CIPHER_CTX_set_padding(decryptCTX_, 1);
    EVP_CipherInit_ex(decryptCTX_, NULL, NULL, key, iv, 0);
    
    int ivLength = EVP_CIPHER_iv_length(cipher);
    encryptIV_ = std::string((char*)iv, ivLength);
    decryptIV_ = encryptIV_;
    memset(key, 0, EVP_MAX_KEY_LENGTH);
}

Crypto::~Crypto()
{
    EVP_CIPHER_CTX_cleanup(encryptCTX_);
    EVP_CIPHER_CTX_cleanup(decryptCTX_);
}

WukongBase::Net::Packet Crypto::encrypt(const char* data, int size)
{
    std::vector<char> outbuf(size + EVP_MAX_BLOCK_LENGTH);
    int outlen;
    EVP_CipherUpdate(encryptCTX_, (unsigned char*)&*outbuf.begin(), &outlen, (unsigned char*)data, size);
    outbuf.resize(outlen);
    return WukongBase::Net::Packet(std::move(outbuf));
}

WukongBase::Net::Packet Crypto::decrypt(const char* data, int size)
{
    std::vector<char> outbuf(size + EVP_MAX_BLOCK_LENGTH);
    int outlen;
    EVP_CipherUpdate(decryptCTX_, (unsigned char*)&*outbuf.begin(), &outlen, (unsigned char*)data, size);
    outbuf.resize(outlen);
    return WukongBase::Net::Packet(std::move(outbuf));
}

void Crypto::setDecryptIV(const std::string& iv)
{
    decryptIV_ = iv;
    EVP_CipherInit_ex(decryptCTX_, NULL, NULL, NULL, (unsigned char*)decryptIV_.c_str(), 0);
}

const std::string& Crypto::getCipherNameByType(CipherType type)
{
    assert(type < kCipherTypeMaxSupported);
    return supportedCipher[type];
}

CipherType Crypto::getCipherTypeByName(const std::string& name)
{
    for (int i = kCipherTypeRC4; i < kCipherTypeMaxSupported; i++) {
        if(name.compare(supportedCipher[i]) == 0) {
            return (CipherType)i;
        }
    }
    return kCipherTypeMaxSupported;
}
