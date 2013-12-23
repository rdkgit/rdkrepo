/* ConcentricCirclesLayout.java

   COPYRIGHT 2007 KRUPCZAK.ORG, LLC.

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

package org.krupczak.Cartographer;

import java.util.Arrays;
import java.util.Comparator;
import javax.swing.JScrollPane;
import java.awt.geom.Point2D;
import java.awt.geom.Rectangle2D;
import org.jgraph.JGraph;
import org.jgraph.graph.*;
import com.jgraph.layout.JGraphFacade;
import com.jgraph.layout.JGraphLayout;

/** Layout class that really just does concentric circles of nodes
 * using the number of edges (in/out) as a basis for choosing which
 * nodes are closest to the center of the window.  Obtain position
 * and size of vertices to layout, store locally in layout if needed.
 * Use graph functions to obtain edges and neighbors and then set
 * locations.  Use basic trigonometry to position vertices.
 * @author Bobby Krupczak, rdk@krupczak.org
 * @version $Id: ConcentricCirclesLayout.java 42 2008-08-04 02:09:23Z rdk $
 **/

public class ConcentricCirclesLayout implements JGraphLayout {

   /* class variables and methods *********************** */
   public static double defaultRadiusFactor = 1.5; 
   public static double defaultRotationFactor = Math.PI/12.0; /* 15-degrees */

   /* instance variables ******************************** */

   /** radius increment, between concentric circles, is a function of
    * radius factor and size of node.  Incrementing radius factor adds
    * more spacing between rings. **/
   public double radiusFactor;

   /** rotation factor rotates each ring slightly so that nodes are
     * not all aligned at the same angle.  (0..2*pi) **/
   public double rotationFactor;

   public JScrollPane ourPane;
   public JGraph theGraph;

   /* constructors  ************************************* */
   ConcentricCirclesLayout() 
   { 
       ourPane = null;
       theGraph = null; 

       radiusFactor = defaultRadiusFactor;
       rotationFactor = defaultRotationFactor;

       return;
   }

   /* private methods *********************************** */

   /* public methods ************************************ */

   /** Is there already a node at given location? If so, we do not
    * want to place a second one there. **/
   public boolean nodeAtLocation(JGraphFacade g, Object v, double x, double y)
   {
       Object[] vertices;
       int i;
       Point2D d;

       vertices = g.getVertices().toArray();

       if ((vertices == null) || (vertices.length == 0)) return false;

       // System.out.println("     nodeAtLocation looking for "+x+","+y);

       for (i=0; i<vertices.length; i++) {

           if (vertices[i] == v) continue; /* dont compare against myself */

           d = g.getLocation(vertices[i]);

           //System.out.println("     nodeAtLocation checking against "+
           //                 d.getX()+","+d.getY());

           if ((d.getX() == x) && (d.getY() == y)) {
	       //System.out.println("Layout: already node at "+x+","+y);
              return true;
           }
       }

       return false;
   }

   public double getRadiusFactor() { return radiusFactor; }
   public double getRotationFactor() { return rotationFactor; }

   public void setRadiusFactor(double factor) { radiusFactor = factor; }
   public void setRotationFactor(double factor) 
   { 
       rotationFactor = factor;
       if ((rotationFactor < 0.0)|| (rotationFactor > Math.PI*2))
	  rotationFactor = defaultRotationFactor;
   }

   public void setScrollPane(JScrollPane thePane) { ourPane = thePane; }

   public void setGraph(JGraph theGraph) { this.theGraph = theGraph; }

   public Point2D getNewOrigin(JGraphFacade graph)
   {
       Rectangle2D bounds = graph.getCellBounds();

       if (bounds == null)
	   return (Point2D) new Point2D.Double(0,0);

       // bounds of a box that encloses the graph
       double gh = bounds.getHeight();
       double gw = bounds.getWidth();

       // bounds of the viewport that displays the graph
       double vh = ourPane.getViewport().getHeight();
       double vw = ourPane.getViewport().getWidth();

       // we want to center it in the viewport if possible, otherwise
       // origin at (0,0)

       double x = (vw - gw) / 2; if (x < 0) x = 0;
       double y = (vh - gh) / 2; if (y < 0) y = 0;

       //System.out.println("ViewPort dimensions: "+vw+","+vh);
       //System.out.println("Graph Bounds: "+gw+","+gh);
       //System.out.println("New Origin: "+x+","+y);

       return (Point2D) new Point2D.Double(x,y);
   }

   /**  get distance between two vertices using standard geometry
    * formulas; we do this because even if we move vertices around,
    * the edges are not necessarily updated until the graph cache
    * itself is edited dont bother with distance if one of the
    * vertices is at 0,0 since thats a temporary location used during
    * the layout algorithm
    **/
   public double getVertexDistance(JGraphFacade g, Object a, Object b)
   {
        Point2D pa, pb;
        Double d;

        pa = g.getLocation(a);
        pb = g.getLocation(b);

        if ((pa.getX() == 0.0) && (pa.getY() == 0.0)) {
	    //System.out.println("getVertexDistance: vertex a is at 0,0");
            return 0.0;
        }
        if ((pb.getX() == 0.0) && (pb.getY() == 0.0)) {
	    //System.out.println("getVertexDistance: vertex b is at 0,0");
            return 0.0;
        }

        d = Math.sqrt(
                      Math.pow(pa.getX() - pb.getX(),2) + 
	              Math.pow(pa.getY() - pb.getY(),2)
		     );

        return d;
   }
 
   /** get total distance from this vertex to its neighbors we use
     * neighbors because two systems may have multiple edges between
     * them and we dont want to double count we dont count distance to
     * neighbors that currently are at 0,0
     **/
   public double getTotalNeighborDistance(JGraphFacade g, Object v)
   {
       Object[] n;
       int i;
       Double total;

       // if vertex is at 0,0, dont bother summing
       if ((g.getLocation(v).getX() == 0.0) && 
           (g.getLocation(v).getY() == 0.0)) {
	  System.out.println("getTotalDistance: vertex is at 0,0");
	  return 0.0;
       }

       n = g.getNeighbours(v,false).toArray();

       //System.out.println("getTotalNeighborDistance: "+
       //                   n.length+" neighbors");
       //System.out.println("getTotalNeighborDistance: "+g.getEdges(v).length+
       //                   " edges");

       total = 0.0;

       for (i=0; i<n.length; i++) {
           total += getVertexDistance(g,v,n[i]);
       }

       //System.out.println("getTotalNeighborDistance: "+total);
 
       return total;
   }

   /** run the algorithm to layout the nodes/edges using our own
    * algorithm; caller than edits the graph with output of the facade
    **/
   public void run(JGraphFacade graph) 
   {
       Object[] vertices = null;
       Object[] edges = null;
       Object[] allEdges = null;
       DefaultGraphCell cell;
       DefaultEdge edge;
       double nodeHeight, nodeWidth, nodeSize, phi, fudge;
       double initialRadius, radius, radiusIncrement;
       int nodesPerRing,i,j, ringNumber;
       double xOff, yOff;

       if (graph == null) {
	  System.out.println("CCircles: run w/o facade");
          return;
       }

       vertices = graph.getVertices().toArray();
       allEdges = graph.getEdges().toArray();

       //System.out.println("Layout: starting with "+vertices.length+" vertices and "+allEdges.length+" edges");

       if (vertices == null || vertices.length == 0) {
	   System.out.println("ConcentricCirclesLayout starting but no vertices");
	   return;
       }

       if ((allEdges == null) || (allEdges.length == 0)) {
	  System.out.println("Layout: ccircles found no edges");
	  return;
       }

       // pull out a Trig book to figure out the functions for placing
       // points along a circle in Cartesian coordinates!

       // we use same graph/icon for each node and are 
       // assuming that the names wont be very much different
       // in size from each other
       nodeHeight = graph.getBounds(vertices[0]).getHeight();
       nodeWidth = graph.getBounds(vertices[0]).getWidth();

       // we should sort based on number of neighbors (since it will look
       // nicer) because a system could have lots of dependencies
       // to one other system but that wont clutter up our display
       // we could sort by number of dependencies as well based
       // on the sortMetric parameter in our comparator

       // sort based on the number of neighbors each vertex has;
       // GraphCellComparator is generic and basically uses JGraph
       // functions to figure out how many edges or neighors a
       // vertex has
       Arrays.sort(vertices,new GraphCellComparator(graph,GraphCellComparator.COMPARE_NEIGHBORS));

       // go through and set the location of each node to be 0,0
       // as an initial location
       for (i=0; i<vertices.length; i++) graph.setLocation(vertices[i],0,0);

       // figure out some parameters related to number nodes per ring, 
       // number of rings, etc.

       nodeSize = Math.max(nodeHeight,nodeWidth);
       radius = 2*nodeSize;
       radiusIncrement = radiusFactor*nodeSize;
 
       // take the size of the area we are working with and
       // divide by two; thats our new origin for our concentric circles
       // by adding this offset, we shift our circles lower right
       //xOff = graph.getGraphBounds().getWidth()/2;
       //yOff = graph.getGraphBounds().getHeight()/2;

       xOff = theGraph.getCenterPoint().getX();
       yOff = theGraph.getCenterPoint().getY();

       // with each ring, we want to slightly rotate the circle so that
       // each ring's first node does not start at (0,y)
       // so, we use a fudge factor based on ring number * PI/12
       // PI/12 = 15-degrees; this factor is called "fudge"
       
       i = 0; ringNumber = 0;

       while (i<vertices.length) {

           nodesPerRing = (int)((Math.PI * radius) / nodeSize);
           phi = (2*Math.PI)/nodesPerRing; /* angle between nodes */
           fudge = rotationFactor*ringNumber;
           j = 0;

           while (j < nodesPerRing && i <vertices.length) {

             cell = (DefaultGraphCell)vertices[i];

             // for rings >= 1, we would like to position
             // the vertices so that their edges cross the center
             // the least; we'd like to keep them closest to the
             // vertices they are connecting to.

             // even if we set a location of a vertex, the length of edges
             // does not seem to get updated until the layout cache is 
             // edited with the output of the layout

             // if we try to calculate the distance between the two 
             // vertices, using graph.getDistance(),
             // that seems to be incorrect as well

             if (ringNumber == 0) {

                graph.setLocation(vertices[i],
                                  radius*Math.cos(j*phi+fudge)+xOff,
                                  radius*Math.sin(j*phi+fudge)+yOff);
                //System.out.println("Vertex "+i+" "+c);
             }
             else {

                // ringNumber > 0 ; we use heuristics to place the
                // node around the ring

                /* for each node, find place that it has least 
                   neighbor distance */
		int z=0;
                int minJ=0;
                double minDistance = 1e12;
                double di,newX,newY;
	        for (z=0; z<nodesPerRing; z++) {

                    newX = radius*Math.cos(z*phi+fudge)+xOff;
                    newY = radius*Math.sin(z*phi+fudge)+yOff;
		    graph.setLocation(vertices[i],newX,newY);

                    // figure out neighbor distance for proposed placement
                    di = getTotalNeighborDistance(graph,vertices[i]);

                    if ((di < minDistance) && 
                        (nodeAtLocation(graph,vertices[i],newX,newY) == false)) {
                       minDistance = di; minJ = z; 
                    }
                }

                graph.setLocation(vertices[i],
                                  radius*Math.cos(minJ*phi+fudge)+xOff,
                                  radius*Math.sin(minJ*phi+fudge)+yOff);

                // figure out neighbor distance for proposed placement
                //System.out.println("Vertex "+i+" "+c+" at "+
                //                   radius*Math.cos(minJ*phi+fudge)+xOff
                //                   +","+
                //                   radius*Math.sin(minJ*phi+fudge)+yOff
                //                   +" min distance "
                //                   +minDistance);

             } /* ringNumber > 0 */
             
	     j++; 
             i++;

           } /* while vertices in a ring */

           // increment radius for next ring
           radius += radiusIncrement;
           ringNumber += 1;

       } /* while vertices */

   }

} /* class ConcentricCirclesLayout */
