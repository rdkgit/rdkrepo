/* Sudoku.java

   COPYRIGHT 2006 KRUPCZAK.ORG, LLC.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
   USA
 
   For more information, visit:
   http://www.krupczak.org/
*/

/** GUI for Sudoku puzzle solver
   @author Bobby Krupczak, rdk@krupczak.org
   @version $Id: Sudoku.java 16 2008-07-21 14:12:38Z rdk $
   @see SudokuPuzzle
   @see TestSudoku
**/

import javax.swing.*;
import java.awt.BorderLayout;
import java.awt.event.*;
import java.awt.GridBagLayout;
import java.awt.GridBagConstraints;
import javax.swing.table.*;
import javax.swing.event.ChangeEvent;
import java.lang.NumberFormatException;
import java.awt.Color;

public class Sudoku implements ActionListener {

   /* class variables and methods *********************** */
   private static void usage(String argv[]) {
	System.out.println("Usage: java Sudoku");
        System.exit(-1);
   }

   private static void createAndShowGUI()
   {
        // create and set up the content area
        //   table, buttons, callbacks, etc.
        Sudoku s = new Sudoku();
   }

   public static void main(String argv[])
   {
        javax.swing.SwingUtilities.invokeLater(new Runnable() {
            public void run() {
                createAndShowGUI();
            }
        });
   }

   /* instance variables ******************************** */
   SudokuPuzzle thePuzzle;
   int size;
   JTable theTable;
   JFrame frame;
   int[][] theElements; // 0..size-1 by 0..size-1
   JButton solveButton, clearButton, exitButton;
   DefaultTableModel theModel;

   /* constructors  ************************************* */
   public Sudoku() 
   {
       int i,j;

       size = 9;
       thePuzzle = new SudokuPuzzle(9);
       theElements = new int[9][9];

       //Make sure we have nice window decorations.
       JFrame.setDefaultLookAndFeelDecorated(true);
       JFrame.setDefaultLookAndFeelDecorated(false);

       //Create and set up the window.
       frame = new JFrame("Sudoku puzzle solver by Bobby Krupczak");
       frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
       frame.getContentPane().setLayout(new GridBagLayout());

       GridBagConstraints c =  new GridBagConstraints();
       c.fill = GridBagConstraints.HORIZONTAL;
       c.anchor = GridBagConstraints.CENTER;

       // table 
       theModel = new DefaultTableModel(size,size);
       theTable = new JTable(theModel);
       //theTable.setDefaultEditor(Integer.class, new IntegerEditor(1,9));
       theTable.setShowGrid(true);
       theTable.setColumnSelectionAllowed(false);
       theTable.setRowSelectionAllowed(false);

       //theTable.setGridColor(Color.black);

       // initialize the table so it has Integers as objects
       //for (i=0; i<9; i++) 
       //    for (j=0; j<9; j++)
       //        theTable.setValueAt(new Integer("0"),i,j);
 
       TableColumn column = null;
       for (i=0; i<9; i++) {
           column = theTable.getColumnModel().getColumn(i);
           column.setPreferredWidth(50);
       }

       // buttons
       solveButton = new JButton("Solve");
       solveButton.setToolTipText("Press this button to solve the puzzle");
       solveButton.addActionListener(this);

       clearButton = new JButton("Clear");
       clearButton.setToolTipText("Press this button to clear the puzzle");
       clearButton.addActionListener(this);

       c.gridx = 0;
       c.gridy = 0;
       c.gridwidth = 2;
       frame.getContentPane().add(theTable,c);

       c.gridx = 0;
       c.gridy = 1;
       c.gridwidth = 1;
       frame.getContentPane().add(clearButton,c);

       c.gridx = 1;
       c.gridy = 1;
       c.gridwidth = 1;
       frame.getContentPane().add(solveButton,c);

       // display the window
       frame.pack();
       frame.setVisible(true);

   }

   /* private methods *********************************** */
   private void clearPuzzle()
   {
      int i,j;

      for (i=0; i<size; i++)
          for (j=0; j<size; j++)
              theTable.setValueAt("",i,j);
   }

   private void solvePuzzle()
   {
      int i,j;
      boolean b;
      String aStr;
      Object o;

      // if we click solve w/o letting the editor know that we are
      // finished with editing, the value wont get put in the
      // table model and we wont see it when we get values
      // so, tell cell editor to stop editing and accept values

      if (theTable.getCellEditor() == null) {
         return;
      }

      theTable.getCellEditor().stopCellEditing();
    
      // get the values from the grid
      for (i=0; i<size; i++) {
          for (j=0; j<size; j++) {
              o = theTable.getValueAt(i,j);	      
              if (o == null) {
		 theElements[i][j] = 0;
              }
	      else {
	         aStr = (String)o.toString();
                 try {
                   theElements[i][j] = Integer.valueOf(aStr);
                   if ((theElements[i][j] < 1) || (theElements[i][j] > 9)) {
                       JOptionPane.showMessageDialog(frame,"Invalid number "+theElements[i][j]);
                       theElements[i][j] = 0;
                       theTable.setValueAt("",i,j);
                       return;
                   }
                   //System.out.println("Value is now "+theElements[i][j]);
                 } catch (NumberFormatException ex) { theElements[i][j] = 0; }
              }
          }
      }

      // set them in the puzzle
      thePuzzle.setElements(theElements);
      //thePuzzle.printElements();

      // solve
      b = thePuzzle.solvePuzzle();

      // check return
      if (b == true) {
          int[][] newElements;
          //System.out.println("Puzzle solved!");
          //thePuzzle.printElements();
          newElements = thePuzzle.getElements();
          for (i=0; i<size; i++) {
              for (j=0; j<size; j++) {
                  theTable.setValueAt(new Integer(newElements[i+1][j+1]),i,j);
              }
          }
          JOptionPane.showMessageDialog(frame,"Puzzle solved!");
      }
      else {
          //System.out.println("Puzzle not solved!");
          JOptionPane.showMessageDialog(frame,"Puzzle not solved");
      }
   }

   /* public methods ************************************ */
   public void actionPerformed(ActionEvent e) 
   {
      JButton buttonSource;

      buttonSource = (JButton)(e.getSource());

      if (buttonSource == solveButton)
	 solvePuzzle();

      if (buttonSource == clearButton)
	 clearPuzzle();


   } /* actionPerformed */

} /* class TestSudoku */
