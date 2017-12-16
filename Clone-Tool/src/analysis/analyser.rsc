module analysis::analyser


import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import IO;
import List;
import String;
import DateTime;
import Set;
import Map;
import Node;
import config;

public map[node, lrel[node, loc, int]] buckets = (); // Map of unique nodes
public map[node, lrel[tuple[node, loc, int], tuple[node,loc, int]]] clones = ();
public rel[node, int] bucketMass = {};
public map[node, loc] ignoredBuckets = ();

public lrel[tuple[node, loc, int], tuple[node,loc, int]] getClones(loc projectLocation, set[Declaration] ast) {
	// Source for our approach:
	//http://leodemoura.github.io/files/ICSM98.pdf
	map[node, loc] ignoredBuckets = (); // Map of nodes we do not wish to visit. These nodes have been determined to be clones, 
										//but are saved together with their location to differentiate them.
	
	println("##########################################################################");
	println("Started hashing the subtrees to buckets at <(printTime(now()))>");
	visit(ast) {
		case node i: {
				//if total mass of node is greater than the threshold
			    int mass = getMass(i);
				if (mass >= getMassThreshold()) {
					addNodeToMap(i, mass, projectLocation);
				}	
		}
	}
	
	println("Buckets: <size(buckets)>");
	
	println("Ended hashing the subtrees to buckets at <(printTime(now()))>");
	println("##########################################################################");
	println("Started clone detection at <(printTime(now()))>");
	
	// Step 3
	//##############################################################	
	
	for(bucket <- buckets) {	
			list[node] nodes = [subTree | <subTree,_,_> <- buckets[bucket]];
			if(size(nodes) >= 2) {
				println("were in");
			lrel[tuple[node, loc, int], tuple[node,loc, int]] allBucketRelations = getAllBucketRelations(buckets[bucket]);
			println("BucketRelations: <size(allBucketRelations)>");
			for(relation <- allBucketRelations) {
				
				//TODO: implement similarity check				
				if (clones[relation[0][0]]?) {
					clones[relation[0][0]] += relation;
				} else {
					clones[relation[0][0]] = [relation];
				}
				removeSubClonesForRelation(relation[0][0]);
						
			}
		}
	}
	
	println("Ended clone detection at <(printTime(now()))>");
	
	return clones;
}

private void removeSubClonesForRelation(lrel[tuple[node, loc, int], tuple[node,loc, int]] relation) {
	removeSubClonesForSubTree(relation[0]);
	removeSubClonesForSubTree(relation[1]);
}

private void removeSubClonesForSubTree(tuple[node,loc,int] subTree) {
	visit (subTree[0]) {
		case node n: {
			loc location = subTree[1];
			for (<i, j> <- clones) {
				if (i == location || j == location) {
					clones = delete(clones, indexOf(clones, <i, j>));
				}
			}
		}
	}	
}

public lrel[tuple[node, loc, int], tuple[node,loc, int]] getAllBucketRelations(lrel[node, loc, int] bucket) {
	lrel[tuple[node, loc, int], tuple[node, loc, int]] bucketRelations = [];
	//add all possible relations of pairs between subtrees to one another
	bucketRelations += bucket * bucket;
	return bucketRelations;
}

public void addNodeToMap(node i, int mass, loc projectLocation) {

	loc location = getNodeLocation(i, projectLocation);
	if (buckets[i]?) {
			println("existing");
		buckets[i] += <i,location, mass>;
	} else {
		buckets[i] = [<i,location, mass>];
	}
	bucketMass += <i, mass>;
	
}

public loc getNodeLocation(node i, loc location) {		
		//http://tutor.rascal-mpl.org/Rascal/Libraries/analysis/m3/AST/src/src.html
		if (Declaration d := i && d.src?) {
				location = d.src;
		} else if (Statement s := i && s.src?) {
				location = s.src;	
		} else if (Expression e := i && e.src?) {
				location = e.src;
		} else {
				location = getUnknownLoc();
		}
		return location;
}

public loc getUnknownLoc() { 
 	loc unknown = |unknown:///|;
	unknown = unknown[offset = 1];
	unknown = unknown[length = 1];
	unknown = unknown[begin = <1,1>];
	unknown = unknown[end = <11,1>];
	return unknown;
}

private int getMass(node i) {
	int mass = 0;
	visit(i) {
		case node _ : mass += 1;
	}
	return mass;
}