import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:path/path.dart';

import 'package:csv/csv.dart';
import 'package:csv_to_xml/csv_to_xml.dart' as csv_to_xml;
import 'package:xml/xml.dart';

void main(List<String> arguments) async{
  final input = File('eval_labels.csv').openRead();
  var rows = await input.transform(utf8.decoder).transform(CsvToListConverter(shouldParseNumbers: false)).toList();
  var data = rows.map((row) => 

     Annotation(row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7])
  ).toList();

  var groupedAnnotations = [];
  var group = [];

  for(final annotation in data){
    if (group.isEmpty){
      group.add(annotation);
    }else if (group[0].filename == annotation.filename){
      group.add(annotation);
    }else{
      groupedAnnotations.add(group);
      group = [];
      group.add(annotation);
    }
  }


List<XmlDocument> xmlData = [];
for(group in groupedAnnotations){
    var builder =  xml.XmlBuilder();
    builder.element('annotation', nest: (){
      builder.element('folder', nest: 'VOC2007');
      builder.element('filename', nest: group[0].filename);
      builder.element('source', nest: (){
        builder.element('database', nest: 'The VOC2007 Database');
        builder.element('annotation', nest: '');
        builder.element('image', nest: 'flickr');
        builder.element('flickrid', nest: '341012865');
      });
      builder.element('owner', nest: (){
        builder.element('flickrid', nest: 'Fried Camels');
        builder.element('name', nest: 'Jinky the Fruit Bat');
      });
      builder.element('size', nest: (){
        builder.element('width', nest: group[0].width);
        builder.element('height', nest: group[0].height);
        builder.element('depth', nest: '3');
      });
      builder.element('segmented', nest: '0');
      for (final annotation in group){
        builder.element('object', nest: (){
          builder.element('name', nest: annotation.className);
          builder.element('pose', nest: 'undefined');
          builder.element('truncated', nest: '1');
          builder.element('difficult', nest: '0');
          builder.element('bndbox', nest: (){
            builder.element('xmin', nest: annotation.xmin);
            builder.element('ymin', nest: annotation.ymin);
            builder.element('xmax', nest: annotation.xmax);
            builder.element('ymax', nest: annotation.ymax);
          });
        });
      }

    });
      xmlData.add(builder.build());
}
    

  //print(xmlData[1].toXmlString(pretty: true, indent: '\t'));
  for (final annotation in xmlData){
    var name = annotation.findAllElements('filename').toList()[0].text;
    File tmpFile = File(name);
    var name2 = basenameWithoutExtension(tmpFile.path);
   await File('eval/${name2}.xml').writeAsString(annotation.toXmlString(pretty: true, indent: '\t'));

  }

}

class Annotation{
  final String filename;
  final String width;
  final String height;
  final String className;
  final String xmin;
  final String ymin;
  final String xmax;
  final String ymax;

  Annotation(this.filename, this.width, this.height, this.className, this.xmin, this.ymin, this.xmax, this.ymax);
}