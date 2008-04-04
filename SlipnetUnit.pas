unit SlipnetUnit;

interface

uses classes, basicimpulse, abstractimpulses;

type
    Tnodetype = (delete_this_nonsense_please, guardian_node, juggler_node, no_attackers, nothing);

    Tnode= class
               Parameters: TParamAbstractRole;
               activation: integer;
               associations: tlist;
               nodetype: Tnodetype;
               BOUND_TO: TParamabstractRole;

               constructor create;
               Procedure activate (r: integer);
               function GetAssociatedNode (T:Tnodetype): tnode;
               Procedure Spread_Activation;
               Procedure Considerations; virtual; abstract;
               Procedure Create_Neighboring_Nodes;  virtual; abstract;
               Procedure Add_Node (Tp: TNodetype; st: integer; activationlevel:integer);
               Procedure Decay;
          end;

    TAssociation= class
                       strenght:integer;
                       node: tnode;
                   end;

    TGuardianNode = class (Tnode)
                          Constructor create (P: TParamAbstractRole);
                          procedure Considerations; Override;
                          procedure Create_Neighboring_nodes; Override;
                    end;


    TNoAttackersNode = class (tnode)
                          Side:boolean;
                          Constructor create (P:TParamAbstractRole);
                          procedure Considerations; Override;
                          procedure Create_Neighboring_nodes; Override;
                    end;

    TInterceptorNode = class (tguardiannode)
                           Constructor create (P: TParamAbstractRole);
                           procedure Considerations; Override;
                           {Procedure Create_Neighboring_Nodes; override;}
                    end;

    TJugglerNode = class (Tnode)
                          Parameters: TParamAbstractRole;
                          Constructor create (P:TParamAbstractRole);
                          procedure Considerations; Override;
                          Procedure Create_Neighboring_Nodes; override; 
                    end;


Function GetNodeFactoryMethod(Tp:TNodetype; P1:TParamAbstractRole):Tnode;

implementation

uses mainunit, impulseconsiderations, externalmemoryunit;

Function GetNodeFactoryMethod(Tp:TNodetype; P1:TParamAbstractRole):Tnode;
var N:^tnode;
begin
     new(N);
     case Tp of
          guardian_node: N^:=tguardianNode.create(P1);
          juggler_node:  N^:=tJugglerNode.create(P1);
          no_attackers: N^:=TNoAttackersNode.create(P1);
     end;
     result:=N^;
end;

function Tnode.GetAssociatedNode (T:Tnodetype): tnode;
var count:integer;  A: Tassociation;
begin
     result:=nil;
     for count:= 0 to Associations.count-1 do  {error is here: no nodes are created!}      
     begin
          A:=Associations.items[count];
          if (A.node.nodetype=T) then
             result:=A.node;
     end;
end;


Constructor Tnode.create;
begin
     Associations:=Tlist.Create;
     create_neighboring_nodes;
end;

Procedure Tnode.Spread_activation;
var x1: integer; A:tassociation; n:tnode;
begin
     for x1:=0 to associations.count-1 do
     begin
          A:=associations.items[x1];
          n:=A.node;
          if (n.activation<activation) then
             n.activation:= n.activation + ((activation-n.activation) * (A.strenght div 100));
     end;
end;


Procedure Tnode.Decay;
begin
     activation:= round(activation * 0.4);
end;

procedure Tnode.activate (r:integer); {gives r activation to the node}
begin
     activation:=activation+r;
     Spread_Activation;  {once done here... not on every decay point}
     Considerations;     {must be done by the main program...
                          always scanning the active nodes & posting impulses...}
end;

Procedure Tnode.Add_Node (Tp: TNodetype; st: integer; activationlevel:integer);
var A: ^Tassociation;
begin
     New (A);
     A^:=tassociation.Create;
     {where are the parameters my friend?}
     A.node:= GetNodeFactoryMethod(Tp, Parameters);

                                   {We have a problem... if this guy is being created right now...
                                   it will be again and again...
                                   how can we converge on him afterwards from another emergent points?
                                   solution:  even if they have distinct backgrounds,
                                   all will have the same considerations. This is beautiful!!!!}

     A.node.activation:=self.activation;
     A.node.nodetype:=tp;
     A.strenght:=st;
     Associations.Add(A^);
     A.node.activate(activationlevel);
end;

{===========================================================================================}
{===========================================================================================}
{===========================================================================================}

Constructor TNoAttackersNode.create (P:TParamAbstractRole);
begin
     Parameters:=P;
     nodetype:=No_attackers;
     inherited create;
end;

procedure TNoAttackersNode.Considerations;
var I: ^Timpulse;
    P:^TParamGuardianConsiderations;
begin
     new (P);
     P^:=TParamGuardianConsiderations.Create;
     P.pmemo:=form1.Memo1;
     P.Origin:=Parameters.Origin;
     P.Node:=self;

     new (i);
     P.impulsepointer:=i;
     i^:=TNoAttackersConsiderations.create(P^, activation);
end;

procedure TNoAttackersNode.Create_Neighboring_nodes;
begin
end;

{===========================================================================================}
{===========================================================================================}
{===========================================================================================}

Constructor TGuardianNode.create (P:TParamAbstractRole);
begin
     Parameters:=P;
     nodetype:=guardian_node;
     inherited create;
end;

Procedure TGuardianNode.Considerations;
var I: ^Timpulse;
    P:^TParamGuardianConsiderations;
begin
     new (P);
     P^:=TParamGuardianConsiderations.Create;
     P.pmemo:=form1.Memo1;
     P.Trajectory:=Parameters.Trajectory;
     P.Node:=self;

     new (i);
     P.impulsepointer:=i;
     i^:=TGuardianConsiderations.create(P^, activation);
end;


Procedure TGuardianNode.Create_Neighboring_Nodes;
begin
     Add_Node (juggler_node, 80, activation);
     Add_Node (no_attackers, 80, 10);
end;



{===========================================================================================}
{===========================================================================================}
{===========================================================================================}
Constructor TInterceptorNode.create (P:TParamAbstractRole);
begin
     Parameters:=P;
     nodetype:=guardian_node;
     inherited create(P);
end;

Procedure TInterceptorNode.Considerations;
var I: ^Timpulse;
    P:^TParamGuardianConsiderations;
begin
     new (P);
     P^:=TParamGuardianConsiderations.Create;
     P.pmemo:=form1.Memo1;
     P.Trajectory:=Parameters.Trajectory;
     P.Node:=self;

     new (i);
     P.impulsepointer:=i;
     i^:=TInterceptorConsiderations.create(P^, activation);
end;

{===========================================================================================}
{===========================================================================================}
{===========================================================================================}

Constructor TJugglerNode.create (P:TParamAbstractRole);
begin
     Parameters:=P;
     nodetype:=juggler_node;
     inherited create;

     {create new assossiated nodes if activation exceeds threshold}
     If activation>10 then  activation:=10;
end;

Procedure TJugglerNode.Considerations;
var I: ^Timpulse;
    P:^TParamJugglerConsiderations;
    squ:tsquare;
begin
     new (P);
     P^:=TParamJugglerConsiderations.Create;
     P.pmemo:=form1.Memo1;
     P.Origin:=Parameters.Origin;
     P.DestinationSquare:=squ;  {BUG We need to put the promotion square here!!!!!}
     P.Trajectory:=Parameters.Trajectory;
     P.Node:=self;

     new (i);
     P.impulsepointer:=i;
     i^:=TJugglerConsiderations.create(P^, 10);
end;

Procedure TJugglerNode.Create_Neighboring_Nodes;
begin
end;


{===========================================================================================}
{===========================================================================================}
{===========================================================================================}



end.
