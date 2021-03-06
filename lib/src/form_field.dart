import 'package:equatable/equatable.dart';
import 'package:flutter_floc/flutter_floc.dart';
import 'package:meta/meta.dart';

class FormField<Value> extends Equatable {
  String _name;
  FormInput<Value> _input;
  String _error;
  List<FieldValidator<Value>> validators;
  Value _defaultValue;

  /// Create a new FormField that could get passed to a FormBloc addFields method
  ///
  /// It could takes a list of validators on the field.
  FormField({
    @required String name,
    @required Value defaultValue,
    List<FieldValidator<Value>> validators,
  }) {
    this.validators = validators ?? [];
    this._defaultValue = defaultValue;
    this._name = name;
    this._input = FormInput<Value>(defaultValue);
  }

  FormField<Value> copyWith(
      {String name, Value defaultValue, FieldValidator<Value> validators}) {
    final formField = FormField(
      name: name ?? this._name,
      defaultValue: defaultValue ?? this._defaultValue,
      validators: validators ?? this.validators,
    );
    formField._input = this._input.copyWith();
    formField._error = this._error;
    return formField;
  }

  /// Change the field value
  void setValue(Value value) {
    this._input.setValue(value);
  }

  void setTouched() {
    this._input.setTouched();
  }

  /// Reset the field to its default value
  void reset() {
    this._input.reset(this._defaultValue);
  }

  void addValidators(List<FieldValidator<Value>> validators) {
    if (validators != null && validators.length > 0) {
      this.validators.addAll(validators);
    }
  }

  String validate([Map<String, FormField> fieldDependencies]) {
    setTouched();

    if (fieldDependencies == null) {
      fieldDependencies = {};
    }

    if (this.validators != null && this.validators.length > 0) {
      for (FieldValidator<Value> validator in validators) {
        final List<String> fieldSubscriptionNames =
            validator.getFieldSubscriptionNames();

        final Map<String, FormField> validatorFieldDependencies = {};
        fieldSubscriptionNames.forEach((name) {
          if (fieldDependencies[name] == null) {
            throw Exception(
              'Error when validating field `$_name` : The field `$name` is missing in dependency.',
            );
          }
          validatorFieldDependencies[name] = fieldDependencies[name];
        });

        final validatorsFieldValueDependencies = validatorFieldDependencies
            .map((key, field) => MapEntry(key, field.value));

        this._error =
            validator.run(this._input.value, validatorsFieldValueDependencies);

        if (this._error != null) return this._error;
      }
    }
    return null;
  }

  List<String> getAllFieldSubscriptionNames() {
    List<String> names = [];
    this.validators.forEach((validator) {
      names.addAll(validator.getFieldSubscriptionNames());
    });
    return names;
  }

  /// Get field name
  String get name => this._name;

  // Get field error (String), returns null if there is no error
  String get error => this._error;

  /// Get default value
  Value get defaultValue => this._defaultValue;

  /// Get field value
  Value get value => this._input.value;

  /// Return true if the field had been touched, false otherwise
  bool get isTouched => this._input.isTouched();

  /// Return true if the field is pure, false otherwise
  bool get isPure => this._input.isPure();

  @override
  List<Object> get props => [_input, _error, validators, _name, _defaultValue];
}
