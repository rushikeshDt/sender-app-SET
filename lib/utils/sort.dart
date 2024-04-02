import 'package:sender_app/presentation/screens/notification_screen.dart';

sort(List<MyModel> modelList) {
  int i, j;
  int n = modelList.length;
  bool swapped;
  for (i = 0; i < n - 1; i++) {
    swapped = false;
    for (j = 0; j < n - i - 1; j++) {
      DateTime date1 = DateTime.parse(modelList[j].key);
      DateTime date2 = DateTime.parse(modelList[j + 1].key);
      if (date1.compareTo(date2) > 0) {
        MyModel temp = modelList[j];
        modelList[j] = modelList[j + 1];
        modelList[j + 1] = temp;
        swapped = true;
      }
    }

    // If no two elements were swapped
    // by inner loop, then break
    if (swapped == false) break;
  }
  return modelList;
}
