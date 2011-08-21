{-# LANGUAGE FlexibleInstances #-}
module Test.Data.Network.Address.IP (tests) where
import Data.Bits (shift)
import Data.List (intercalate)
import Data.Network.Address.IP
import Data.Word
import Numeric (showHex)
import Test.Framework
import Test.Framework.Providers.QuickCheck2
import Test.QuickCheck
import Test.QuickCheck.Arbitrary

-- |Integral type for 32bit network masks (i.e. 0..32)
newtype Mask32 = Mask32 {getMask32 :: Word8} deriving (Show, Read)

newtype Mask128 = Mask128 {getMask128 :: Word8} deriving (Show, Read)

instance Arbitrary IPv4 where
    arbitrary = fmap (toAddress . toInteger) (arbitrary :: Gen Word32)

instance Arbitrary IPv6 where
    arbitrary = do
        a <- arbitrary :: Gen Word64
        b <- arbitrary :: Gen Word64
        return . toAddress . toInteger $ (a `shift` 64) + b

instance Arbitrary (IPSubnet IPv4) where
    arbitrary = do
        ip <- arbitrary :: Gen IPv4
        size <- arbitrary :: Gen Mask32
        return . readSubnet $ showAddress ip ++ "/" ++ show (getMask32 size)

instance Arbitrary (IPSubnet IPv6) where
    arbitrary = do
        ip <- arbitrary :: Gen IPv6
        size <- arbitrary :: Gen Mask128
        return . readSubnet $ showAddress ip ++ "/" ++ show (getMask128 size)

instance Arbitrary Mask32 where
    arbitrary = fmap (Mask32 . fromIntegral) (choose (0, 32) :: Gen Int)

instance Arbitrary Mask128 where
    arbitrary = fmap (Mask128 . fromIntegral) (choose (0, 128) :: Gen Int)

tests = [ testGroup "IPv4"
            [ testGroup "Read/Show"
                [ testProperty "Symmetric Read/Show" prop_ipv4_symmetric_readable
                , testProperty "Symmetric readAddress/showAddress" prop_ipv4_symmetric_parsable
                ]
            , testGroup "Binary"
                [ testProperty "Symmetric to/from" prop_ipv4_symmetric_tofrom
                ]
            , testGroup "Subnet"
                [ testProperty "Symmetric IPv4 Read/Show" prop_subnet_ipv4_symmetric_readable
                ]
            ]
        , testGroup "IPv6"
            [ testGroup "Read/Show"
                [ testProperty "Symmetric Read/Show" prop_ipv4_symmetric_readable
                , testProperty "Symmetric readAddress/showAddress" prop_ipv6_symmetric_parsable
                ]
            , testGroup "Binary"
                [ testProperty "Symmetric to/from" prop_ipv6_symmetric_tofrom
                ]
            , testGroup "Subnet"
                [ testProperty "Symmetric IPv6 Read/Show" prop_subnet_ipv6_symmetric_readable
                ]
            ]
        , testGroup "Netmask"
            [ testProperty "Symmetric toMask/fromMask" prop_mask_tofrom
            ]
        ]

prop_fun_id :: (Eq a) => (a -> a) -> a -> Bool
prop_fun_id f x = f x == f (f x)

prop_ipv4_symmetric_readable :: IPv4 -> Bool
prop_ipv4_symmetric_readable ip = (read . show) ip == id ip

prop_ipv4_symmetric_parsable :: IPv4 -> Bool
prop_ipv4_symmetric_parsable ip = (readAddress . showAddress) ip == id ip

prop_ipv4_symmetric_tofrom :: IPv4 -> Bool
prop_ipv4_symmetric_tofrom ip = (toAddress . fromAddress) ip == id ip

prop_subnet_ipv4_symmetric_readable :: IPSubnet IPv4 -> Bool
prop_subnet_ipv4_symmetric_readable subnet = (readSubnet . showSubnet) subnet == id subnet

prop_ipv6_symmetric_readable :: IPv6 -> Bool
prop_ipv6_symmetric_readable ip = (read . show) ip == id ip

prop_ipv6_symmetric_parsable :: IPv6 -> Bool
prop_ipv6_symmetric_parsable ip = (readAddress . showAddress) ip == id ip

prop_ipv6_symmetric_tofrom :: IPv6 -> Bool
prop_ipv6_symmetric_tofrom ip = (toAddress . fromAddress) ip == id ip

prop_subnet_ipv6_symmetric_readable :: IPSubnet IPv6 -> Bool
prop_subnet_ipv6_symmetric_readable subnet = (readSubnet . showSubnet) subnet == id subnet

prop_mask_tofrom :: Mask32 -> Bool
prop_mask_tofrom x = (fromMask m :: Word32) == (fromIntegral . getMask32) x
    where m = (toMask . getMask32) x :: Word32
