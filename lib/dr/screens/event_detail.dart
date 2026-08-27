import 'package:bsbschool/features/events/domain/entities/school_event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final SchoolEvent event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 8),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height:12),
              _backHeader(context),
              SizedBox(height:22),
              Text(widget.event.title,style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),),
              SizedBox(height:12),
              Text(DateFormat('dd.MM.yyyy').format(widget.event.date!)),
              SizedBox(height:12),
              Text(widget.event.description),
            ],
          ),
        ),
      ),
    );
  }


}

Widget _backHeader(BuildContext context) {
  return InkWell(
    onTap: ()=>Navigator.pop(context),
    child: Row(
      children: [
        Icon(Icons.close,size: 22,),
        SizedBox(width:12),
        Text('Bağla',style: TextStyle(
          fontSize: 17,
        ),)
      ],
    ),
  );
}
