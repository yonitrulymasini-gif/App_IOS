# 📱 Flutter iOS sans Mac : Build avec Codemagic + Installation via AltStore

Ce guide explique comment construire et installer une application Flutter sur iPhone sans Mac et sans compte Apple Developer payant.

## Prérequis

* Projet Flutter fonctionnel
* Compte GitHub
* Compte Apple gratuit
* PC Windows
* iPhone

Structure minimale du projet :

```text
mon_app/
├── android/
├── ios/
├── lib/
├── pubspec.yaml
└── ...
```

### Firebase (optionnel)

Si votre application utilise Firebase, ajoutez simplement le fichier :

```text
ios/Runner/GoogleService-Info.plist
```

---

# 1. Ajouter Codemagic

Créer un fichier `codemagic.yaml` à la racine du dépôt.

```yaml
workflows:
  ios-workflow:
    name: iOS Build
    max_build_duration: 60
    instance_type: mac_mini_m2

    environment:
      flutter: stable
      xcode: latest
      cocoapods: default

    scripts:
      - name: Get packages
        script: flutter packages pub get

      - name: Build iOS unsigned
        script: flutter build ios --release --no-codesign

      - name: Package IPA
        script: |
          cd build/ios/iphoneos
          mkdir Payload
          cp -r Runner.app Payload/
          zip -r -9 app-unsigned.ipa Payload
          rm -rf Payload

    artifacts:
      - build/ios/iphoneos/app-unsigned.ipa
```

---

# 2. Envoyer le projet sur GitHub

```bash
git add codemagic.yaml
git commit -m "Add Codemagic configuration"
git push origin main
```

---

# 3. Générer l'IPA avec Codemagic

## Connexion du dépôt

1. Créer un compte sur https://codemagic.io
2. Connecter GitHub
3. Ajouter le dépôt Flutter

Exemple :

```text
github.com/votre-compte/App_IOS
```

## Lancer un build

```text
Start New Build
    ↓
iOS Build
```

Attendre la fin de la compilation.

## Télécharger l'IPA

```text
Build Details
    ↓
Artifacts
    ↓
app-unsigned.ipa
```

Télécharger le fichier généré.

---

# 4. Installer AltStore sur Windows

## Installer iTunes et iCloud

⚠️ Désinstaller les versions Microsoft Store de :

* iTunes
* iCloud

Puis installer les versions officielles Apple :

* iTunes 64 bits
* iCloud pour Windows

Redémarrer le PC.

---

## Installer AltServer

Téléchargement :

https://altstore.io

Installer puis lancer :

```text
AltServer.exe
```

en tant qu'administrateur.

---

## Installer AltStore sur l'iPhone

1. Brancher l'iPhone en USB
2. Accepter « Faire confiance à cet ordinateur »
3. Ouvrir AltServer

```text
AltServer
    ↓
Install AltStore
    ↓
Sélectionner l'iPhone
```

4. Entrer l'Apple ID

AltStore est alors installé sur l'iPhone.

---

# 5. Activer le mode développeur

Sur l'iPhone :

```text
Réglages
    ↓
Confidentialité et sécurité
    ↓
Mode développeur
```

Activer le mode développeur puis redémarrer l'appareil.

---

# 6. Installer l'application Flutter

Transférer le fichier :

```text
app-unsigned.ipa
```

sur l'iPhone via :

* AirDrop
* iCloud Drive
* OneDrive
* Google Drive
* Email

Puis :

```text
Fichiers
    ↓
app-unsigned.ipa
    ↓
Partager
    ↓
Ouvrir avec AltStore
```

AltStore signe automatiquement l'application avec votre Apple ID puis l'installe.

---

# 7. Faire confiance à l'application

Si nécessaire :

```text
Réglages
    ↓
Général
    ↓
VPN et gestion de l'appareil
```

Sélectionner votre Apple ID puis :

```text
Faire confiance
```

---

# 8. Lancer l'application

Une fois installée :

```text
Accueil iPhone
    ↓
Votre application
```

L'application Flutter est prête à être utilisée.

---

# Renouvellement de la signature

Avec un compte Apple gratuit :

* Signature valide 7 jours

## Renouvellement automatique

Conditions :

* AltServer ouvert sur le PC
* Même réseau Wi-Fi que l'iPhone

AltStore renouvelle automatiquement les signatures.

## Renouvellement manuel

```text
AltStore
    ↓
My Apps
    ↓
Refresh All
```

---

# Workflow complet

```text
Flutter
   ↓
GitHub
   ↓
Codemagic
   ↓
app-unsigned.ipa
   ↓
AltStore
   ↓
Signature Apple ID
   ↓
Installation iPhone
```

---

# Avantages

✅ Aucun Mac requis

✅ Aucun abonnement Apple Developer (99 $/an)

✅ Compatible Windows

✅ Build iOS dans le cloud

✅ Installation gratuite via AltStore

✅ Renouvellement automatique possible

✅ Compatible avec la majorité des applications Flutter

---

## Résumé

Cette méthode permet de développer une application Flutter sous Windows, de générer un fichier IPA via Codemagic et d'installer l'application sur un iPhone gratuitement grâce à AltStore, sans Mac et sans compte développeur Apple payant.
