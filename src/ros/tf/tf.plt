:- use_module(library('rostest')).
:- use_module(library('lang/query')).
:- use_module(library('lang/scope')).
:- use_module(library('db/mongo/client')).
:- use_module(library('semweb/rdf_db')).

:- use_module('tf').
:- use_module('tf_mongo').

:- begin_rdf_tests(
		'tf',
		'package://knowrob/owl/test/swrl.owl',
		[ namespace('http://knowrob.org/kb/swrl_test#'),
		  setup(tf_setup),
		  cleanup(tf_cleanup)
		]).

:- rdf_meta(test_set_pose(r,+,+)).
:- rdf_meta(test_get_pose(r,+,+)).
:- rdf_meta(test_trajectory(r,+,+,+)).
:- rdf_meta(test_transform_pose(r,+,+)).
:- rdf_meta(test_is_unlocalized(r,+)).
:- rdf_meta(tf_get_pose(r,?,+)).

tf_setup :-
	tf_mng_drop,
	tf_logger_enable.

tf_cleanup :-
	tf_logger_disable,
	tf_mng_drop.

% some test facts
test_pose_fred0([world,[1.0,0.4,2.32],[0.0,0.0,0.0,1.0]], 1593178679.123).
test_pose_fred1([world,[2.0,0.4,2.32],[0.0,0.0,0.0,1.0]], 1593178680.123).
test_pose_fred2([world,[3.0,0.4,2.32],[0.0,0.0,0.0,1.0]], 1593178681.123).
test_pose_alex1(['Fred',[0.0,1.0,0.0],[0.0,0.0,0.0,1.0]], 1593178680.123).
test_pose_alex2([world,[0.0,0.0,1.0],[0.0,0.0,0.0,1.0]], 1593178681.123).
test_pose_alex3(['Fred',[0.0,1.0,0.0],[0.0,0.0,0.0,1.0]], 1593178682.123).

test_set_pose(Object,Pose,Stamp) :-
	time_scope(=(Stamp), =<('Infinity'), FScope),
	assert_true(tf:tf_set_pose(Object,Pose,FScope)).

test_get_pose(Object,Stamp,Expected) :-
	time_scope(=<(Stamp), >=(Stamp), QScope),
	assert_true(tf:tf_get_pose(Object,_,QScope,_)),
	( tf:tf_get_pose(Object,Actual,QScope,_)
	-> assert_unifies(Actual,Expected)
	;  true
	).

test_trajectory(Obj,Begin,End,Expected) :-
	assert_true(tf_mongo:tf_mng_trajectory(Obj,Begin,End,_)),
	( tf_mongo:tf_mng_trajectory(Obj,Begin,End,Actual)
	-> assert_unifies(Actual,Expected)
	;  true
	).

test_transform_pose(Object,Stamp,Query) :-
	time_scope(=<(Stamp), >=(Stamp), QScope),
	assert_true(tf:tf_get_pose(Object,Query,QScope,_)).

test_lookup(Frame,Stamp,Expected) :-
	assert_true(tf:tf_mng_lookup(Frame,Stamp,Stamp,_,_,_)),
	( tf:tf_mng_lookup(Frame,Stamp,Stamp,Actual,_,_)
	-> assert_unifies(Actual,Expected)
	;  true
	).

test_lookup_fails(Frame,Stamp) :-
	assert_false(tf:tf_mng_lookup(Frame,Stamp,Stamp,_,_,_)).

test_is_unlocalized(Object,Stamp) :-
	time_scope(=<(Stamp), >=(Stamp), QScope),
	assert_false(tf:tf_get_pose(Object,_,QScope,_)).

test('tf_pose') :-
	test_pose_fred0(Pose0,Stamp0),
	Past   is Stamp0 - 1.0,
	Future is Stamp0 + 1.0,
	%%
	test_is_unlocalized(test:'Fred',Stamp0),
	test_set_pose(test:'Fred',Pose0,Stamp0),
	test_get_pose(test:'Fred',Stamp0,Pose0),
	test_get_pose(test:'Fred',Future,Pose0),
	test_is_unlocalized(test:'Fred',Past).

test('tf_mongo_lookup') :-
	test_pose_fred0(Pose0,Stamp0),
	Past is Stamp0 - 1.0,
	test_lookup('Fred',Stamp0,Pose0),
	test_lookup_fails('Fred',Past).

test('tf_pose_memory') :-
	test_pose_fred0(Pose0,Stamp0),
	test_pose_fred1(Pose1,Stamp1),
	test_pose_fred2(Pose2,Stamp2),
	Stamp01 is 0.5*(Stamp0 + Stamp1),
	Future is Stamp2 + 1.0,
	%%
	test_set_pose(test:'Fred',Pose1,Stamp1),
	test_set_pose(test:'Fred',Pose2,Stamp2),
	%%
	test_get_pose(test:'Fred',Stamp0,Pose0),
	test_get_pose(test:'Fred',Stamp01,Pose0),
	test_get_pose(test:'Fred',Stamp1,Pose1),
	test_get_pose(test:'Fred',Stamp2,Pose2),
	test_get_pose(test:'Fred',Future,Pose2).

test('tf_trajectory') :-
	test_pose_fred0(Pose0,Stamp0),
	test_pose_fred1(Pose1,Stamp1),
	test_pose_fred2(Pose2,Stamp2),
	test_trajectory(test:'Fred',Stamp0,Stamp2,
		[Stamp0-Pose0, Stamp1-Pose1, Stamp2-Pose2]),
	test_trajectory(test:'Fred',Stamp1,Stamp2,
		[Stamp1-Pose1, Stamp2-Pose2]).

test('tf_transform_pose') :-
	test_pose_alex1(Pose1,Stamp1),
	test_set_pose(test:'Alex',Pose1,Stamp1),
	test_get_pose(test:'Alex',Stamp1,Pose1),
	test_transform_pose(test:'Alex',Stamp1,[world,[2.0,1.4,2.32],_]),
	test_transform_pose(test:'Fred',Stamp1,['Alex',_,_]).

%% used for resource expansion since tf:tf_get_pose doesn't have that.
tf_get_pose(Obj, PoseQuery, QScope) :-
	tf:tf_get_pose(Obj, PoseQuery, QScope, _).

%% number_similar(+Delta, +A, +B) is det.
%
% check if two numbers are within delta of each other.
% if A and B are lists, process them recursively.
% if A and B are neither both numbers, nor both lists, this predicate fails.
number_similar(Delta, A, B) :-
	number(A),
	number(B),
	!,
	Delta >= abs(A-B).

number_similar(Delta, A, B) :-
	is_list(A),
	is_list(B),
	!,
	maplist(number_similar(Delta),A,B).

test('tf_transform_pose3') :-
	% TODO: this test needs refactoring to be
	% in the same style as the other tests here.
	test_pose_alex1(PoseAlex, Stamp),
	test_pose_fred1(PoseFred, Stamp),
	time_scope(=<(Stamp), >=(Stamp), QScope),
	PoseMike = [world, [0.0,0.0,1.0], [0.0,0.0,0.0,1.0]],
	test_set_pose(test:'Alex',PoseAlex,Stamp),
	test_get_pose(test:'Alex',Stamp,PoseAlex),
	test_set_pose(test:'Fred',PoseFred,Stamp),
	test_get_pose(test:'Fred',Stamp,PoseFred),
	test_set_pose(test:'Mike',PoseMike,Stamp),
	test_get_pose(test:'Mike',Stamp,PoseMike),
	% test_transform_pose doesn't check the numbers in the list
	% because algebra.cpp doesn't check them, so i do it myself
	tf_get_pose(test:'Alex', ['Fred', Pose1, _], QScope),
	assert_true(number_similar(0.0001, Pose1, [0.0,1.0,0.0])),
	tf_get_pose(test:'Fred', ['Alex', Pose2, _], QScope),
	assert_true(number_similar(0.0001, Pose2, [0.0,-1.0,0.0])),
	tf_get_pose(test:'Alex', [world, Pose3, _], QScope),
	assert_true(number_similar(0.0001, Pose3, [2.0,1.4,2.32])),
	tf_get_pose(test:'Mike', ['Alex', Pose4, _], QScope),
	assert_true(number_similar(0.0001, Pose4, [-2.0,-1.4,-1.32])),
	tf_get_pose(test:'Alex', ['Mike', Pose5, _], QScope),
	assert_true(number_similar(0.0001, Pose5, [2.0,1.4,1.32])).


test('tf_transform_pose_and_half_rotate',
	 [
		 setup(tf_setup),
		 cleanup(tf_cleanup)
	 ]) :-
	% TODO: this test needs refactoring to be
	% in the same style as the other tests here.
	test_pose_alex1(PoseAlex, Stamp),
	test_pose_fred1(PoseFred, Stamp),
	time_scope(=<(Stamp), >=(Stamp), QScope),
	PoseMike = [world, [0.0,0.0,1.0], [0.0,0.0,1.0,0.0]],
	test_set_pose(test:'Alex',PoseAlex,Stamp),
	test_get_pose(test:'Alex',Stamp,PoseAlex),
	test_set_pose(test:'Fred',PoseFred,Stamp),
	test_get_pose(test:'Fred',Stamp,PoseFred),
	test_set_pose(test:'Mike',PoseMike,Stamp),
	test_get_pose(test:'Mike',Stamp,PoseMike),
	% test_transform_pose doesn't check the numbers in the list
	% because algebra.cpp doesn't check them, so i do it myself
	tf_get_pose(test:'Alex', ['Fred', Pose1, _], QScope),
	assert_true(number_similar(0.0001, Pose1, [0.0,1.0,0.0])),
	tf_get_pose(test:'Fred', ['Alex', Pose2, _], QScope),
	assert_true(number_similar(0.0001, Pose2, [0.0,-1.0,0.0])),
	tf_get_pose(test:'Alex', [world, Pose3, _], QScope),
	assert_true(number_similar(0.0001, Pose3, [2.0,1.4,2.32])),
	tf_get_pose(test:'Mike', ['Alex', Pose4, _], QScope),
	assert_true(number_similar(0.0001, Pose4, [-2.0,-1.4,-1.32])),
	tf_get_pose(test:'Alex', ['Mike', Pose5, _], QScope),
	assert_true(number_similar(0.0001, Pose5, [-2.0,-1.4,1.32])).


%test('tf_is_at') :-
%	test_pose_fred0(Pose0,Stamp0),
%	assert_true(kb_call(
%		during(is_at(test:'Fred',Pose0), [Stamp0,Stamp0])
%	)).

:- end_tests('tf').
