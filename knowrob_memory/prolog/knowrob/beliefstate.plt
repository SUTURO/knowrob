
:- begin_tests(knowrob_beliefstate).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- use_module(library('lists')).
:- use_module(library('random')).
:- use_module(library('semweb/rdfs')).
:- use_module(library('semweb/owl')).
:- use_module(library('knowrob/owl')).
:- use_module(library('knowrob/temporal')).
:- use_module(library('knowrob/objects')).
:- use_module(library('knowrob/beliefstate')).

:- owl_parser:owl_parse('package://knowrob_household/owl/kitchen.owl').
:- rdf_db:rdf_register_ns(knowrob, 'http://knowrob.org/kb/knowrob.owl#',  [keep(true)]).

:- dynamic test_object/1.

test(belief_new_object) :-
  belief_new_object(knowrob:'Cup', Cup),
  rdfs_individual_of(Cup, knowrob:'Cup'),
  rdfs_individual_of(Cup, owl:'NamedIndividual'),
  assertz(test_object(Cup)).

test(belief_at_update) :-
  test_object(Cup),
  belief_at_update(Cup, ['map',_,[1.0,0.0,0.0],[1.0,0.0,0.0,0.0]]),
  current_object_pose(Cup, _), !.
  
test(belief_at_update2) :-
  test_object(Cup),
  object_frame_name(Cup, F1),
  belief_perceived_at(knowrob:'Cup', [F1,_,[1.0,1.0,0.0],[1.0,0.0,0.0,0.0]], 0.0, Cup2),
  current_object_pose(Cup2,[F1,_,_,_]), !.

test('belief_at_location(equal)') :-
  belief_existing_object_at(knowrob:'Cup', ['map',_,[1.0,0.0,0.0],[1.0,0.0,0.0,0.0]], 0.0, Cup),
  test_object(Cup), !.

test('belief_at_location(fails)', [fail]) :-
  belief_existing_object_at(knowrob:'Cup', ['map',_,[1.001,0.001,0.0],[1.0,0.0,0.0,0.0]], 0.0, Cup),
  test_object(Cup), !.

test('belief_at_location(nearby)') :-
  belief_existing_object_at(knowrob:'Cup', ['map',_,[1.001,0.001,0.0],[1.0,0.0,0.0,0.0]], 0.5, Cup),
  test_object(Cup), !.

test(belief_at_update_class) :-
  test_object(Cup),
  belief_perceived_at(knowrob:'Milk', ['map',_,[1.0,0.0,0.0],[1.0,0.0,0.0,0.0]], 0.0, Cup),
  \+ rdfs_individual_of(Cup, knowrob:'Cup'),
  owl_individual_of_during(Cup, knowrob:'Milk'), !.

test(belief_at_update_class2) :-
  test_object(Cup),
  belief_perceived_at(knowrob:'Cup', ['map',_,[1.0,0.0,0.0],[1.0,0.0,0.0,0.0]], 0.0, Cup),
  owl_individual_of_during(Cup, knowrob:'Cup'),
  \+ owl_individual_of_during(Cup, knowrob:'Milk'), !.

test(belief_temporalized_type) :-
  test_object(Cup),
  owl_individual_of_during(Cup,knowrob:'Cup', [0.0,T2]),
  owl_individual_of_during(Cup,knowrob:'Milk', [T2,T3]),
  owl_individual_of_during(Cup,knowrob:'Cup', [T3]), !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- end_tests(knowrob_beliefstate).
