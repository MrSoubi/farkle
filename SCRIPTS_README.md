Storage & Movement helper scripts
=================================

Résumé
------
Ce projet a été refactorisé pour séparer les responsabilités autour du stockage/banking des dés.
Les nouvelles pièces sont :

- `Scripts/position_calculator.gd` : fonctions pures pour calculer les positions de stockage et de bank (pas d'effets de bord). Utilisez `PositionCalculator.calculate_storing_positions(...)` et `PositionCalculator.calculate_bank_positions(...)`.

- `Scripts/die_mover.gd` : helper chargé d'animer le déplacement d'un dé. Ce fichier est attendu comme autoload (singleton) nommé `DieMover` et expose `prepare_tween_for_die(die, target, ...)` qui prépare un Tween et gèle le dé avant l'animation. Appeler ensuite `await tw.finished` puis dé-geler le dé (le coordinator le fait automatiquement).

- `Scripts/storage_model.gd` : modèle léger (Node) qui contient les listes `stored_dice` et `banked_dice` et expose des méthodes simples (`add_stored`, `remove_stored`, `clear_stored_to_banked`, ...). On crée une instance locale quand on démarre la coordination.

- `Scripts/storage_coordinator.gd` (anciennement `hand.gd`): orchestre les événements (connecte `EventBus`), met à jour `GameContext`, demande au `PositionCalculator` les positions et utilise `DieMover` et `StorageModel` pour animer et suivre les dés.

Notes d'intégration
-------------------
- J'ai laissé `Scripts/hand.gd` comme wrapper (extends `StorageCoordinator`) pour préserver toute référence éventuelle. Le fichier canonique est `storage_coordinator.gd`.
- Ajoutez ces autoloads dans Project Settings -> Autoload (si ce n'est pas déjà fait) :
  - `res://Scripts/die_mover.gd` -> Name: `DieMover`
  - (Optionnel) `res://Scripts/storage_model.gd` -> Name: `StorageModel` (mais la coordinator crée sa propre instance par défaut)

Quick test
----------
1. Ouvrir `Scenes/World.tscn` et vérifier que le Node `Hand` a bien `res://Scripts/storage_coordinator.gd` attaché (cette scène a déjà été mise à jour).
2. Lancer la scène. Cliquer sur un dé -> il doit se déplacer vers la position de stockage, et `Lbl_StoredValue` (lié via `GameContext`) doit s'actualiser.
3. Cliquer à nouveau sur le dé -> il retourne à sa position précédente.
4. Cliquer sur "Garder" -> les dés stockés se déplacent vers la position de bank et deviennent `BANKED`.

Si quelque chose ne marche pas, dites-moi et je corrige rapidement (je peux aussi renommer définitivement `hand.gd` si vous préférez libérer le vieux nom).

Design notes
------------
- Principe : séparation claire entre calcul (PositionCalculator), état (StorageModel) et effets (DieMover). `StorageCoordinator` orchestre le tout.
- Avantages : plus simple à tester, plus modulaire, facile à remplacer l'implémentation d'animation ou la stratégie de positionnement.
