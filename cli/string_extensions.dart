extension StringExtensions on String {
    String capitalizeFirst() {
      if (isEmpty) {
        return this;
      } else {
        return "${this[0].toUpperCase()}${substring(1)}";
      }
    }
}
