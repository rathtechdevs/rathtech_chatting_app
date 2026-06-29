enum AutoLockDuration {
  immediately(0),
  after1min(1),
  after5min(5),
  after15min(15);

  const AutoLockDuration(this.minutes);
  final int minutes;

  static AutoLockDuration fromMinutes(int minutes) => values.firstWhere(
        (d) => d.minutes == minutes,
        orElse: () => AutoLockDuration.immediately,
      );
}
