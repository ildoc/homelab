# Nota: In ambiente locale, questo file può essere sovrascritto con backend.tf.local
# In GitLab CI, questo file viene sovrascritto automaticamente dalla pipeline

terraform {
  # In ambiente CI, questo backend viene sovrascritto dalla configurazione
  # generata automaticamente nella pipeline CI
  backend "http" {
    # Queste impostazioni vengono sovrascritte dal CI/CD
    # Non modificare manualmente questo file
  }
}