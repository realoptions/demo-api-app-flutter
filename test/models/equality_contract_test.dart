import 'package:flutter_test/flutter_test.dart';
import 'package:realoptions/blocs/form/form_bloc.dart';
import 'package:realoptions/components/CustomTextFields.dart';
import 'package:realoptions/models/forms.dart';
import 'package:realoptions/models/models.dart';
import 'package:realoptions/models/pages.dart';

/// The hashCode half of the equality contract: two objects that compare `==`
/// must return the same hashCode. Nothing else in the app asserts this, so
/// every violation below was silent - it only shows up as a Set that will not
/// dedup, a Map that misses a key, or a bloc that re-emits a state it already
/// has.
///
/// These were written while replacing quiver's hash2/hash4 with Object.hash,
/// and two of the classes actually failed them beforehand. They are kept
/// because they pin down behaviour that is easy to break again by adding a
/// field to `==` and forgetting hashCode, or the reverse.
void main() {
  InputConstraint constraint({
    String name = 'vol',
    num? lower = 0.0,
    num? upper = 100.0,
    num defaultValue = 1.0,
  }) =>
      InputConstraint(
        name: name,
        fieldType: FieldType.Float,
        inputType: InputType.Model,
        defaultValue: defaultValue,
        lower: lower,
        upper: upper,
      );

  group('PageState', () {
    test('equal by value across distinct list instances', () {
      final PageState a = PageState(index: 1, showBadges: <bool>[true, false]);
      final PageState b = PageState(index: 1, showBadges: <bool>[true, false]);

      expect(a, equals(b));
      // The bug this replaces: hash2 folded in List.hashCode, which is
      // identity-based, so these two disagreed while `==` (listEquals) said
      // they matched.
      expect(a.hashCode, equals(b.hashCode));
    });

    test('deduplicates in a Set', () {
      final Set<PageState> seen = <PageState>{
        PageState(index: 1, showBadges: <bool>[true, false]),
        PageState(index: 1, showBadges: <bool>[true, false]),
      };
      expect(seen, hasLength(1));
    });

    test('a different index still separates them', () {
      final PageState a = PageState(index: 1, showBadges: <bool>[true]);
      final PageState b = PageState(index: 2, showBadges: <bool>[true]);
      expect(a, isNot(equals(b)));
    });

    test('a different badge list still separates them', () {
      final PageState a = PageState(index: 1, showBadges: <bool>[true, false]);
      final PageState b = PageState(index: 1, showBadges: <bool>[true, true]);
      expect(a, isNot(equals(b)));
    });
  });

  group('InputConstraint', () {
    test('equal by name hashes equal despite differing bounds', () {
      final InputConstraint a = constraint(lower: 0.0, upper: 100.0);
      final InputConstraint b = constraint(lower: -5.0, upper: 7.5);

      // `operator ==` compares `name` alone, so these are equal by the
      // class's own definition.
      expect(a, equals(b));
      // The bug this replaces: hash4(lower, upper, name, defaultValue) hashed
      // three fields that equality ignores, so equal objects hashed apart.
      expect(a.hashCode, equals(b.hashCode));
    });

    test('deduplicates in a Set', () {
      final Set<InputConstraint> seen = <InputConstraint>{
        constraint(lower: 0.0),
        constraint(lower: 99.0),
      };
      expect(seen, hasLength(1));
    });

    test('a different name separates them', () {
      expect(constraint(name: 'vol'), isNot(equals(constraint(name: 'kappa'))));
    });
  });

  group('Model', () {
    test('equal by value hashes equal', () {
      const Model a = Model(value: 'heston', label: 'Heston');
      const Model b = Model(value: 'heston', label: 'Heston');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('label participates in equality', () {
      const Model a = Model(value: 'heston', label: 'Heston');
      const Model b = Model(value: 'heston', label: 'Heston (v2)');
      expect(a, isNot(equals(b)));
    });
  });

  group('SubmitItems', () {
    test('equal by value hashes equal', () {
      const SubmitItems a =
          SubmitItems(value: 2.5, inputType: InputType.Market);
      const SubmitItems b =
          SubmitItems(value: 2.5, inputType: InputType.Market);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inputType participates in equality', () {
      const SubmitItems a =
          SubmitItems(value: 2.5, inputType: InputType.Market);
      const SubmitItems b = SubmitItems(value: 2.5, inputType: InputType.Model);
      expect(a, isNot(equals(b)));
    });
  });

  group('FormItem', () {
    test('equal by value hashes equal', () {
      final FormItem a =
          FormItem(valueAtLastSubmit: '1.0', constraint: constraint());
      final FormItem b =
          FormItem(valueAtLastSubmit: '1.0', constraint: constraint());
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('a different last-submitted value separates them', () {
      final FormItem a =
          FormItem(valueAtLastSubmit: '1.0', constraint: constraint());
      final FormItem b =
          FormItem(valueAtLastSubmit: '2.0', constraint: constraint());
      expect(a, isNot(equals(b)));
    });
  });

  test('the contract holds through a Map key round trip', () {
    // The practical consumer: if hashCode and == disagree, lookups miss even
    // though the key is "equal".
    final Map<Model, String> byModel = <Model, String>{
      const Model(value: 'heston', label: 'Heston'): 'density',
    };
    expect(byModel[const Model(value: 'heston', label: 'Heston')], 'density');
    expect(byModel, hasLength(1));
  });
}
