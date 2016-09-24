//
//  Crypto.h
//  ShadowsocksSW
//
//  Created by Xuhui on 16/8/7.
//  Copyright © 2016年 Xuhui. All rights reserved.
//

#ifndef Crypto_h
#define Crypto_h

#include "net/Packet.h"
#include "openssl/evp.h"
#include <string>

enum CipherType {
    kCipherTypeRC4,
    kCipherTypeAES126CFB,
    kCipherTypeAES192CFB,
    kCipherTypeAES256CFB,
    kCipherTypeBFCFB,
    kCipherTypeCAMELLIA128CFB,
    kCipherTypeCAMELLIA192CFB,
    kCipherTypeCAMELLIA256CFB,
    kCipherTypeCAST5CFB,
    kCipherTypeDESCFB,
    kCipherTypeIDEACFB,
    kCipherTypeRC2CFB,
    kCipherTypeSEEDCFB,
    kCipherTypeMaxSupported
};

class Crypto {
public:
    Crypto(CipherType cipherType, const std::string& password);
    ~Crypto();
    
    WukongBase::Net::Packet encrypt(const char* data, int size);
    WukongBase::Net::Packet decrypt(const char* data, int size);
    
    const std::string& getEncryptIV() const
    {
        return encryptIV_;
    }
    
    void setDecryptIV(const std::string& iv);
    
    size_t getIVLength() const {
        return encryptIV_.size();
    }
    
    static const std::string& getCipherNameByType(CipherType type);
    static CipherType getCipherTypeByName(const std::string& name);
private:
    CipherType cipherType_;
    EVP_CIPHER_CTX* encryptCTX_;
    EVP_CIPHER_CTX* decryptCTX_;
    std::string encryptIV_;
    std::string decryptIV_;
};

#endif /* Crypto_h */
