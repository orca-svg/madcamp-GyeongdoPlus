class RepositoryResult<T> {
  final T? data;
  final String? errorMessage;
  final bool success;

  const RepositoryResult.success(this.data)
    : success = true,
      errorMessage = null;

  const RepositoryResult.failure(this.errorMessage)
    : success = false,
      data = null;
}
