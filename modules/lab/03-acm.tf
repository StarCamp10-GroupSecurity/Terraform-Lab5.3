resource "tls_private_key" "main" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}


resource "tls_self_signed_cert" "main" {
  #   private_key_pem = file("private_key.pem")
  private_key_pem = tls_private_key.main.private_key_pem

  subject {
    common_name  = "heytamvo.com"
    organization = "Starcamp Batch 10, Group Security"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.main.private_key_pem
  certificate_body = tls_self_signed_cert.main.cert_pem
}