terraform {
  backend "oci" {
    bucket        = "terraform-state-bucket"
    namespace     = "gr5ugxwrsywe"       # veja abaixo como obter
    region        = "sa-saopaulo-1"
    key           = "oke/terraform.tfstate"
  }
}
