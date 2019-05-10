/*

- 2 HTTPS C2
- 2 HTTPS Redirectors

- 1 DNS C2
- 1 DNS Redirector


- 3 Domains

- C2s hosted on GCP
- Redirectors hosted on GCP
- Domains managed by 4n7m4n

*/

// Minimum required TF version is 0.10.0

terraform {
  required_version = ">= 0.10.0"
}


// -------------------------------------

module "https_c2" {
  source = "./modules/google/https-c2"
  count=2
}

//module "dns_c2" {
//  source = "./modules/google/dns-c2"
//}

module "https_rdir" {
  source = "./modules/google/https-rdir"
  count = 2
  redirect_to = "${module.https_c2.ips}"
}

//module "dns_rdir" {
//  source = "./modules/google/dns-rdir"
//  redirect_to = "${module.dns_c2.ips}"
//}

//module "https_rdir1_records" {
//  source = "./modules/google/create-dns-record"
//  // Change this domain
//  domain = "<CHANGETHIS.com>"
//  type = "A"
//  records = {
//  // Change this domain name
//    "<CHANGETHIS.com>" = "${module.https_rdir.ips[0]}"
//  }
//}

//module "https_rdir2_records" {
//  source = "./modules/google/create-dns-record"
//  // Change this domain name
//  domain = "<CHANGETHIS.com>"
//  type = "A"
//  records = {
//  // Change this domain name
//    "<CHANGETHIS.com>" = "${module.https_rdir.ips[1]}"
//  }
//}

//module "dns_rdir_records" {
//  source = "./modules/google/create-dns-record"
//  count = 2
//  // Change this domain name
//  domain = "<CHANGETHIS.com>"
//  type = "A"
//  records = {
//  // Change this domain name
//    "<CHANGETHIS.com>"     = "${module.dns_rdir.ips[0]}"
//    "ns1.<CHANGETHIS.com>" = "${module.dns_rdir.ips[0]}"
//  }
//}

//module "dns_rdir_ns_record" {
//  source = "./modules/google/create-dns-record"
//  // Change this domain name
//  domain = "<CHANGETHIS.com>"
//  type = "NS"
//  records = {
//  // Change this domain name
//    "dns.<CHANGETHIS.com>" = "ns1.<CHANGETHIS.com>"
//  }
//}

//module "create_certs" {
//  source = "./modules/letsencrypt/create-cert-dns"

//  count = 2
//  domains = ["<CHANGETHIS.com>", "<CHANGETHIS.com>", "<CHANGETHIS.com>" = []]

//  subject_alternative_names = {
//    "<CHANGETHIS.com>" = []
//    "<CHANGETHIS.com>" = []
//  }
//}

output "https-c2-ips" {
  value = "${module.https_c2.ips}"
}

//output "dns-c2-ips" {
//  value = "${module.dns_c2.ips}"
//}

output "https-rdir-ips" {
  value = "${module.https_rdir.ips}"
}

//output "dns-rdir-ips" {
//  value = "${module.dns_rdir.ips}"
//}

//output "https_rdir_domains" {
//  value = "${merge(module.https_rdir1_records.records, module.http_rdir2_records.records)}"
//}

//output "dns_rdir_domains" {
//  value = "${merge(module.dns_rdir_records.records, module.dns_rdir_ns_record.records)}"
//}