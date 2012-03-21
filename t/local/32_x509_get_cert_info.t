#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1130;
use Net::SSLeay;
use File::Spec;

Net::SSLeay::randomize();
Net::SSLeay::load_error_strings();
Net::SSLeay::ERR_load_crypto_strings();
Net::SSLeay::SSLeay_add_ssl_algorithms();

# NOTE: *.pem_dump files are generated by helper script e.g.:
# perl examples/X509_cert_details.pl -dump -pem t/data/cert_twitter.crt.pem > t/data/cert_paypal.crt.pem_dump
#
my $dump = {
  "cert_paypal.crt.pem"       => do(File::Spec->catfile('t', 'data', 'cert_paypal.crt.pem_dump')),
  "cert_twitter.crt.pem"      => do(File::Spec->catfile('t', 'data', 'cert_twitter.crt.pem_dump')),
  "testcert_extended.crt.pem" => do(File::Spec->catfile('t', 'data', 'testcert_extended.crt.pem_dump')),
  "testcert_simple.crt.pem"   => do(File::Spec->catfile('t', 'data', 'testcert_simple.crt.pem_dump')),
  "testcert_strange.crt.pem"  => do(File::Spec->catfile('t', 'data', 'testcert_strange.crt.pem_dump')),
};

for my $f (keys (%$dump)) {
  my $filename = File::Spec->catfile('t', 'data', $f);
  ok(my $bio = Net::SSLeay::BIO_new_file($filename, 'rb'), "BIO_new_file\t$f");
  ok(my $x509 = Net::SSLeay::PEM_read_bio_X509($bio), "PEM_read_bio_X509\t$f");
  
  ok(Net::SSLeay::X509_get_pubkey($x509), "X509_get_pubkey\t$f"); #only test whether the function works  

  ok(my $subj_name = Net::SSLeay::X509_get_subject_name($x509), "X509_get_subject_name\t$f");
  is(my $subj_count = Net::SSLeay::X509_NAME_entry_count($subj_name), $dump->{$f}->{subject}->{count}, "X509_NAME_entry_count\t$f");
  
  #BEWARE: values are not the same across different openssl versions therefore cannot test exact match
  #is(Net::SSLeay::X509_NAME_oneline($subj_name), $dump->{$f}->{subject}->{oneline}, "X509_NAME_oneline\t$f");  
  #is(Net::SSLeay::X509_NAME_print_ex($subj_name), $dump->{$f}->{subject}->{print_rfc2253}, "X509_NAME_print_ex\t$f");  
  like(Net::SSLeay::X509_NAME_oneline($subj_name), qr|/OU=.*?/CN=|, "X509_NAME_oneline\t$f");
  like(Net::SSLeay::X509_NAME_print_ex($subj_name), qr|CN=.*?,OU=|, "X509_NAME_print_ex\t$f");

  for my $i (0..$subj_count-1) {    
    ok(my $entry = Net::SSLeay::X509_NAME_get_entry($subj_name, $i), "X509_NAME_get_entry\t$f:$i");
    ok(my $asn1_string = Net::SSLeay::X509_NAME_ENTRY_get_data($entry), "X509_NAME_ENTRY_get_data\t$f:$i");
    ok(my $asn1_object = Net::SSLeay::X509_NAME_ENTRY_get_object($entry), "X509_NAME_ENTRY_get_object\t$f:$i");
    is(Net::SSLeay::OBJ_obj2txt($asn1_object,1), $dump->{$f}->{subject}->{entries}->[$i]->{oid}, "OBJ_obj2txt\t$f:$i");
    is(Net::SSLeay::P_ASN1_STRING_get($asn1_string), $dump->{$f}->{subject}->{entries}->[$i]->{data}, "P_ASN1_STRING_get.1\t$f:$i");
    is(Net::SSLeay::P_ASN1_STRING_get($asn1_string, 1), $dump->{$f}->{subject}->{entries}->[$i]->{data_utf8_decoded}, "P_ASN1_STRING_get.2\t$f:$i");
    if (defined $dump->{$f}->{entries}->[$i]->{nid}) {
      is(my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object), $dump->{$f}->{subject}->{entries}->[$i]->{nid}, "OBJ_obj2nid\t$f:$i");
      is(Net::SSLeay::OBJ_nid2ln($nid), $dump->{$f}->{subject}->{entries}->[$i]->{ln}, "OBJ_nid2ln\t$f:$i");
      is(Net::SSLeay::OBJ_nid2sn($nid), $dump->{$f}->{subject}->{entries}->[$i]->{sn}, "OBJ_nid2sn\t$f:$i");
    }
  }
  
  ok(my $issuer_name = Net::SSLeay::X509_get_issuer_name($x509), "X509_get_subject_name\t$f");
  is(my $issuer_count = Net::SSLeay::X509_NAME_entry_count($issuer_name), $dump->{$f}->{issuer}->{count}, "X509_NAME_entry_count\t$f");
  is(Net::SSLeay::X509_NAME_oneline($issuer_name), $dump->{$f}->{issuer}->{oneline}, "X509_NAME_oneline\t$f");
  is(Net::SSLeay::X509_NAME_print_ex($issuer_name), $dump->{$f}->{issuer}->{print_rfc2253}, "X509_NAME_print_ex\t$f");

  for my $i (0..$issuer_count-1) {    
    ok(my $entry = Net::SSLeay::X509_NAME_get_entry($issuer_name, $i), "X509_NAME_get_entry\t$f:$i");
    ok(my $asn1_string = Net::SSLeay::X509_NAME_ENTRY_get_data($entry), "X509_NAME_ENTRY_get_data\t$f:$i");
    ok(my $asn1_object = Net::SSLeay::X509_NAME_ENTRY_get_object($entry), "X509_NAME_ENTRY_get_object\t$f:$i");
    is(Net::SSLeay::OBJ_obj2txt($asn1_object,1), $dump->{$f}->{issuer}->{entries}->[$i]->{oid}, "OBJ_obj2txt\t$f:$i");
    is(Net::SSLeay::P_ASN1_STRING_get($asn1_string), $dump->{$f}->{issuer}->{entries}->[$i]->{data}, "P_ASN1_STRING_get.1\t$f:$i");
    is(Net::SSLeay::P_ASN1_STRING_get($asn1_string, 1), $dump->{$f}->{issuer}->{entries}->[$i]->{data_utf8_decoded}, "P_ASN1_STRING_get.2\t$f:$i");
    if (defined $dump->{$f}->{entries}->[$i]->{nid}) {
      is(my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object), $dump->{$f}->{issuer}->{entries}->[$i]->{nid}, "OBJ_obj2nid\t$f:$i");
      is(Net::SSLeay::OBJ_nid2ln($nid), $dump->{$f}->{issuer}->{entries}->[$i]->{ln}, "OBJ_nid2ln\t$f:$i");
      is(Net::SSLeay::OBJ_nid2sn($nid), $dump->{$f}->{issuer}->{entries}->[$i]->{sn}, "OBJ_nid2sn\t$f:$i");
    }
  }
  
  my @subjectaltnames = Net::SSLeay::X509_get_subjectAltNames($x509);
  is(scalar(@subjectaltnames), scalar(@{$dump->{$f}->{subject}->{altnames}}), "subjectaltnames size\t$f");
  for my $i (0..$#subjectaltnames) {
    SKIP: {
      skip('altname types are different on pre-0.9.7', 1) unless Net::SSLeay::SSLeay >= 0x0090700f || ($i%2)==1;
      is($subjectaltnames[$i], $dump->{$f}->{subject}->{altnames}->[$i], "subjectaltnames match\t$f:$i");
    }
  }
  
  #BEWARE: values are not the same across different openssl versions, therefore testing just >0
  #is(Net::SSLeay::X509_subject_name_hash($x509), $dump->{$f}->{hash}->{subject}->{dec}, 'X509_subject_name_hash dec');
  #is(Net::SSLeay::X509_issuer_name_hash($x509), $dump->{$f}->{hash}->{issuer}->{dec}, 'X509_issuer_name_hash dec');
  cmp_ok(Net::SSLeay::X509_subject_name_hash($x509), '>', 0, "X509_subject_name_hash dec\t$f");
  cmp_ok(Net::SSLeay::X509_issuer_name_hash($x509), '>', 0, "X509_issuer_name_hash dec\t$f");
  
  is(Net::SSLeay::X509_issuer_and_serial_hash($x509), $dump->{$f}->{hash}->{issuer_and_serial}->{dec}, "X509_issuer_and_serial_hash dec\t$f");
  is(Net::SSLeay::X509_get_fingerprint($x509, "md5"), $dump->{$f}->{fingerprint}->{md5}, "X509_get_fingerprint md5\t$f");
  is(Net::SSLeay::X509_get_fingerprint($x509, "sha1"), $dump->{$f}->{fingerprint}->{sha1}, "X509_get_fingerprint sha1\t$f");
  
  my $sha1_digest = Net::SSLeay::EVP_get_digestbyname("sha1");
  SKIP: {
    skip('requires openssl-0.9.7', 1) unless Net::SSLeay::SSLeay >= 0x0090700f;
    is(Net::SSLeay::X509_pubkey_digest($x509, $sha1_digest), $dump->{$f}->{digest_sha1}->{pubkey}, "X509_pubkey_digest\t$f");
  }
  is(Net::SSLeay::X509_digest($x509, $sha1_digest), $dump->{$f}->{digest_sha1}->{x509}, "X509_digest\t$f");

  
  SKIP: {
    skip('P_ASN1_TIME_get_isotime requires 0.9.7e+', 2) unless Net::SSLeay::SSLeay >= 0x0090705f;
    is(Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notBefore($x509)), $dump->{$f}->{not_before}, "X509_get_notBefore\t$f");
    is(Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($x509)), $dump->{$f}->{not_after}, "X509_get_notAfter\t$f");
  }
  
  ok(my $ai = Net::SSLeay::X509_get_serialNumber($x509), "X509_get_serialNumber\t$f");

  is(Net::SSLeay::P_ASN1_INTEGER_get_hex($ai), $dump->{$f}->{serial}->{hex}, "serial P_ASN1_INTEGER_get_hex\t$f");
  is(Net::SSLeay::P_ASN1_INTEGER_get_dec($ai), $dump->{$f}->{serial}->{dec}, "serial P_ASN1_INTEGER_get_dec\t$f");
  is(Net::SSLeay::ASN1_INTEGER_get($ai), $dump->{$f}->{serial}->{long}, "serial ASN1_INTEGER_get\t$f");

  is(Net::SSLeay::X509_get_version($x509), $dump->{$f}->{version}, "X509_get_version\t$f");
  
  is(my $ext_count = Net::SSLeay::X509_get_ext_count($x509), $dump->{$f}->{extensions}->{count}, "X509_get_ext_count\t$f");
  for my $i (0..$ext_count-1) {
    ok(my $ext = Net::SSLeay::X509_get_ext($x509,$i), "X509_get_ext\t$f:$i");
    ok(my $asn1_string = Net::SSLeay::X509_EXTENSION_get_data($ext), "X509_EXTENSION_get_data\t$f:$i");
    ok(my $asn1_object = Net::SSLeay::X509_EXTENSION_get_object($ext), "X509_EXTENSION_get_object\t$f:$i");
    SKIP: {
      skip('X509_EXTENSION_get_critical works differently on pre-0.9.7', 1) unless Net::SSLeay::SSLeay >= 0x0090700f;
      is(Net::SSLeay::X509_EXTENSION_get_critical($ext), $dump->{$f}->{extensions}->{entries}->[$i]->{critical}, "X509_EXTENSION_get_critical\t$f:$i");
    }
    is(Net::SSLeay::OBJ_obj2txt($asn1_object,1), $dump->{$f}->{extensions}->{entries}->[$i]->{oid}, "OBJ_obj2txt\t$f:$i");
    
    if (defined $dump->{$f}->{extensions}->{entries}->[$i]->{nid}) {
      is(my $nid = Net::SSLeay::OBJ_obj2nid($asn1_object), $dump->{$f}->{extensions}->{entries}->[$i]->{nid}, "OBJ_obj2nid\t$f:$i");
      is(Net::SSLeay::OBJ_nid2ln($nid), $dump->{$f}->{extensions}->{entries}->[$i]->{ln}, "OBJ_nid2ln nid=$nid\t$f:$i");
      is(Net::SSLeay::OBJ_nid2sn($nid), $dump->{$f}->{extensions}->{entries}->[$i]->{sn}, "OBJ_nid2sn nid=$nid\t$f:$i");
      #BEARE: handling some special cases - mostly things that varies with different openssl versions
      SKIP: {
        if ($nid==103) {
          skip('X509V3_EXT_print output on CRL distribution points differs across openssl versions', 1);
        }
        elsif ($nid==85 && $f eq 'testcert_extended.crt.pem' && Net::SSLeay::SSLeay < 0x0090800f) {
          skip('0.9.7 does not print correctly IPv6 addresses', 1);
        }
        else {
          is(Net::SSLeay::X509V3_EXT_print($ext), $dump->{$f}->{extensions}->{entries}->[$i]->{data}, "X509V3_EXT_print nid=$nid\t$f:$i");
        }
      }
    }
  }
    
  SKIP: {
    skip('crl_distribution_points requires 0.9.7+', scalar(@{$dump->{$f}->{cdp}})+1) unless Net::SSLeay::SSLeay >= 0x0090700f;
    my @cdp = Net::SSLeay::P_X509_get_crl_distribution_points($x509);
    is(scalar(@cdp), scalar(@{$dump->{$f}->{cdp}}), "cdp size\t$f");
    for my $i (0..$#cdp) {
      is($cdp[$i], $dump->{$f}->{cdp}->[$i], "cdp match\t$f:$i");
    }
  }

  my @keyusage = Net::SSLeay::P_X509_get_key_usage($x509);
  my @ns_cert_type = Net::SSLeay::P_X509_get_netscape_cert_type($x509);
  is(scalar(@keyusage), scalar(@{$dump->{$f}->{keyusage}}), "keyusage size\t$f");
  is(scalar(@ns_cert_type), scalar(@{$dump->{$f}->{ns_cert_type}}), "ns_cert_type size\t$f");
  for my $i (0..$#keyusage) {
    is($keyusage[$i], $dump->{$f}->{keyusage}->[$i], "keyusage match\t$f:$i");
  }
  for my $i (0..$#ns_cert_type) {
    is($ns_cert_type[$i], $dump->{$f}->{ns_cert_type}->[$i], "ns_cert_type match\t$f:$i");
  }

  SKIP: {
    my $test_count = 4 + scalar(@{$dump->{$f}->{extkeyusage}->{oid}}) +
                         scalar(@{$dump->{$f}->{extkeyusage}->{nid}}) +
                         scalar(@{$dump->{$f}->{extkeyusage}->{sn}}) +
                         scalar(@{$dump->{$f}->{extkeyusage}->{ln}});

    skip('extended key usage requires 0.9.7+', $test_count) unless Net::SSLeay::SSLeay >= 0x0090700f;
    my @extkeyusage_oid = Net::SSLeay::P_X509_get_ext_key_usage($x509,0);
    my @extkeyusage_nid = Net::SSLeay::P_X509_get_ext_key_usage($x509,1);
    my @extkeyusage_sn  = Net::SSLeay::P_X509_get_ext_key_usage($x509,2);
    my @extkeyusage_ln  = Net::SSLeay::P_X509_get_ext_key_usage($x509,3);
  
    is(scalar(@extkeyusage_oid), scalar(@{$dump->{$f}->{extkeyusage}->{oid}}), "extku_oid size\t$f");
    is(scalar(@extkeyusage_nid), scalar(@{$dump->{$f}->{extkeyusage}->{nid}}), "extku_nid size\t$f");
    is(scalar(@extkeyusage_sn), scalar(@{$dump->{$f}->{extkeyusage}->{sn}}), "extku_sn size\t$f");
    is(scalar(@extkeyusage_ln), scalar(@{$dump->{$f}->{extkeyusage}->{ln}}), "extku_ln size\t$f");

    for my $i (0..$#extkeyusage_oid) {
      is($extkeyusage_oid[$i], $dump->{$f}->{extkeyusage}->{oid}->[$i], "extkeyusage_oid match\t$f:$i");
    }
    for my $i (0..$#extkeyusage_nid) {
      is($extkeyusage_nid[$i], $dump->{$f}->{extkeyusage}->{nid}->[$i], "extkeyusage_nid match\t$f:$i");
    }
    for my $i (0..$#extkeyusage_sn) {
      is($extkeyusage_sn[$i], $dump->{$f}->{extkeyusage}->{sn}->[$i], "extkeyusage_sn match\t$f:$i");
    }
    for my $i (0..$#extkeyusage_ln) {
      is($extkeyusage_ln[$i], $dump->{$f}->{extkeyusage}->{ln}->[$i], "extkeyusage_ln match\t$f:$i");
    }
  }
  
  ok(my $pubkey = Net::SSLeay::X509_get_pubkey($x509), "X509_get_pubkey");
  is(Net::SSLeay::OBJ_obj2txt(Net::SSLeay::P_X509_get_signature_alg($x509)), $dump->{$f}->{signature_alg}, "P_X509_get_signature_alg");
  is(Net::SSLeay::OBJ_obj2txt(Net::SSLeay::P_X509_get_pubkey_alg($x509)), $dump->{$f}->{pubkey_alg}, "P_X509_get_pubkey_alg");  
  is(Net::SSLeay::EVP_PKEY_size($pubkey), $dump->{$f}->{pubkey_size}, "EVP_PKEY_size");
  is(Net::SSLeay::EVP_PKEY_bits($pubkey), $dump->{$f}->{pubkey_bits}, "EVP_PKEY_bits");
  SKIP: {
    skip('EVP_PKEY_id requires 1.0.0+', 1) unless Net::SSLeay::SSLeay >= 0x1000000f;
    is(Net::SSLeay::EVP_PKEY_id($pubkey), $dump->{$f}->{pubkey_id}, "EVP_PKEY_id");
  }

}
