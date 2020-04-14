import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

final String assetName = 'assets/images/tumbleweed.svg';
final Widget svg = SvgPicture.asset(
  assetName,
  height: 160,
  width: 160,
  color: Colors.grey[400],
);

class EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Text(
            "Err... Nothing to see here",
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 24,
                fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        svg,
      ],
    );
  }
}
