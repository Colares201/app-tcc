import 'package:flutter/material.dart';

class  HomePage extends StatelessWidget {
  String nome = 'TCC2/ALAN/META';
  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(nome,
          style: TextStyle(color: const Color.fromARGB(255, 54, 92, 244),
          fontSize: 20.0),
          
          ),
         
          // actions: [
          // Text('xxxxxx')
             
          //],
        ),
          drawer: Drawer(),
          endDrawer: Drawer(),
        body: Container(
            width: 350,
            height: 220,
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                
                  Center(
                    child: Text('Controle de Energia',
                    style: TextStyle(color: const Color.fromARGB(255, 54, 244, 238)
                    ),
                    ),
                  ),
                
            
                   Text('Controle de Energia',
                  style: TextStyle(color: const Color.fromARGB(255, 54, 244, 238)
                  ),
                  ),
                  
            
                  Text('Controle de Energia',
                  style: TextStyle(color: const Color.fromARGB(255, 54, 244, 238)
                  ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children:[
                  Text('teste',
                  style: TextStyle(color: const Color.fromARGB(255, 54, 244, 238)
                  ),
                  ),
                  SizedBox(width: 100,),   
                  Text('teste',
                  style: TextStyle(color: const Color.fromARGB(255, 54, 244, 238)  
                  ),
                  ),
                    ],
                  )
                
                  ],
            ),

        )
      );
  }

}